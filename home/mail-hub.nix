# ==============================================================================
# MAIL HUB MODULE (NEXUS ONLY)
# ==============================================================================
# Please maintain this modular structure unless a redesign is explicitly requested.
#
# This module turns a host into the central mail mirror for the fleet. It is
# imported ONLY by `home/nexus.nix` -- never by `base.nix` -- because exactly one
# machine should hold provider credentials and do the downloading.
#
# It deliberately does NOT redefine any email account. The three accounts live in
# `home/cli.nix` and stay the single source of truth; this file only switches on
# the sync/index engines for them and maps their folder layouts. Nix attrset
# merging does the rest.
#
# ONE sync engine on purpose: mbsync (isync) for all three accounts.
# lieer (Gmail API) was evaluated and rejected -- it syncs into notmuch TAGS over
# a flat maildir, and dovecot serves FOLDERS. Bridging the two needs dovecot's
# virtual mailbox plugin driven by saved searches, which is real complexity in
# the middle of the mail path. Its main advantage was dodging Gmail's IMAP
# throttle, and that argument evaporates once only one machine syncs instead of
# five. See `AI Knowledge Base/mail_sync_hub_plan.md`.
#
# Phase 1 of the plan: sync only. Dovecot (which serves this mirror to the other
# hosts) is a system-level service and belongs in `hosts/nexus.nix`, not here --
# `services.dovecot2` is a NixOS module and is unavailable to Home Manager. It
# goes in the host profile rather than `modules/common.nix` because common.nix is
# for what EVERY NixOS host needs, and only nexus serves mail.
#
# Why a systemd *user* timer here, when `standalone-daemons.nix` says NixOS hosts
# get their daemons system-wide from `modules/common.nix`?
# That rule exists because `etserver` binds a fixed port as root on NixOS, so a
# universal user-level copy would collide with it. Nothing here collides: mail
# sync is inherently user-scoped (the user's Maildir, the user's credentials, the
# user's `accounts.email` declarations), it is hub-only rather than
# every-non-NixOS-host, and it has no system-level counterpart to conflict with.
# ==============================================================================

{ config, pkgs, lib, ... }:

let
  # TIMER OFF until the initial-sync strategy is settled. Flip to true when ready.
  #
  # Not a placeholder -- the current channel set is known-wrong for Gmail. Gmail's
  # IMAP INBOX is 307,361 messages, because the category tabs (Promotions 183k,
  # Updates 95k, Social 19k) live INSIDE INBOX rather than being folders of their
  # own. INBOX therefore overlaps All Mail almost entirely, so these channels
  # would pull ~672k messages to store ~365k unique ones -- double the bandwidth
  # and disk for no gain, against a quota already returning [OVERQUOTA].
  #
  # Masking the unit is not an alternative: home-manager owns
  # ~/.config/systemd/user/mbsync.timer as a nix store symlink, so `systemctl
  # --user mask` refuses, and `disable` is silently reverted by the next
  # activation. Disabling the service here is the only durable off switch.
  #
  # `programs.mbsync` stays enabled, so the binary and isyncrc remain and manual
  # runs still work -- only the scheduled runs stop.
  timerEnabled = false;

  # How often the sync timer fires. Phase 4 may replace polling with goimapnotify
  # IDLE push, at which point this only governs the safety-net run.
  syncFrequency = "*:0/5";

  # Re-index after every sync so notmuch never sees a half-synced store.
  # Cheap: notmuch only walks what changed.
  reindex = "${pkgs.notmuch}/bin/notmuch new";

  # Every account is normalised onto this identical local tree:
  #
  #   INBOX  Archive  Sent  Trash  Junk  Drafts
  #
  # This is the whole point of the mapping below. The providers disagree wildly
  # about naming -- Gmail buries everything under `[Gmail]/`, Outlook says
  # "Deleted Items", Fastmail says "Spam" -- and that disagreement is why the
  # folder list currently looks like a mess in aerc, and why "which one is
  # actually Trash?" is a hard question to answer.
  #
  # The renaming happens AT SYNC TIME. The local maildir genuinely contains one
  # folder called `Trash`. This is not a display filter that leaks the underlying
  # mess back when something goes wrong. Once dovecot serves this tree, a single
  # aerc keybinding works identically across all three accounts.
  # TRAP, verified against home-manager rev e83dffa (modules/programs/mbsync):
  # the per-account `create` / `remove` / `expunge` options are ONLY emitted when
  # `groups == { }`. The moment you define custom channel groups — as this module
  # must, to normalise folder names — `genChannelString` emits nothing but `Far`,
  # `Near` and the channel's own `extraConfig`, and those account-level options
  # are silently dropped. No warning, no error.
  #
  # That is not a cosmetic loss. Without `Create`, mbsync will not create the
  # local maildir folders and the first sync fails outright; without `Expunge`
  # the deletion safety rail this design depends on would simply not exist while
  # appearing to.
  #
  # So the directives live per-channel instead. Values come from the module's own
  # `nearFarMapping`: none→None, maildir→Near, imap→Far, both→Both.
  channelDefaults = {
    Create = "Near";    # create missing folders locally, never invent them upstream
    Remove = "None";    # never propagate folder deletions
    Expunge = "None";   # never purge; deliberate deletion is a MOVE to Trash
    SyncState = "*";    # keep sync state beside the mailbox, as HM does elsewhere
  };

  mkChannel = far: near: {
    farPattern = far;
    nearPattern = near;
    extraConfig = channelDefaults;
  };

  standardChannels = far: {
    inbox = mkChannel "INBOX" "INBOX";
    archive = mkChannel far.archive "Archive";
    sent = mkChannel far.sent "Sent";
    trash = mkChannel far.trash "Trash";
    junk = mkChannel far.junk "Junk";
    drafts = mkChannel far.drafts "Drafts";
  };

  # Note there is deliberately no `create`/`expunge`/`remove` here — see the trap
  # above. Setting them would read as protection while doing nothing.
  safeDefaults = {
    enable = true;
  };
in
{
  # ---------------------------------------------------------------------------
  # Sync engine and index
  # ---------------------------------------------------------------------------
  programs.mbsync.enable = true;

  programs.notmuch = {
    enable = true;
    # With a single sync engine there is no tagging conflict to resolve, so the
    # conventional defaults are correct: `tag:inbox` and `tag:unread` mean what
    # everyone expects. (This was a genuine conflict while lieer was in the
    # design -- lieer derives tags from Gmail labels and needs incoming mail left
    # unmarked.)
    new.tags = [ "unread" "inbox" ];
  };

  services.mbsync = {
    enable = timerEnabled;
    frequency = syncFrequency;
    postExec = reindex;
  };

  # ---------------------------------------------------------------------------
  # Per-account wiring
  #
  # These attrsets MERGE with the definitions in cli.nix -- they do not replace
  # them. Address, realName, flavor, and passwordCommand all stay over there.
  # Gmail authenticates with the app password already in sops, the same
  # credential aerc uses today; no OAuth client is involved in syncing.
  # ---------------------------------------------------------------------------

  accounts.email.accounts.fastmail = {
    mbsync = safeDefaults // {
      groups.fastmail.channels = standardChannels {
        archive = "Archive";
        sent = "Sent";
        trash = "Trash";
        junk = "Spam";
        drafts = "Drafts";
      };
    };
    notmuch.enable = true;
  };

  accounts.email.accounts.live = {
    # cli.nix wires the XOAUTH2 helper only into aerc's `source-cred-cmd`, so
    # there is no account-level password command for mbsync to read. Supply it
    # here rather than in cli.nix, so client aerc behaviour is untouched.
    #
    # This must be nexus's OWN token file. Do not copy `.live-token` from another
    # machine: Microsoft rotates refresh tokens on use, so two hosts sharing one
    # file invalidate each other and produce intermittent auth failures.
    # Generate it on nexus before the first sync (device-code flow, no browser
    # needed on the host).
    passwordCommand =
      "${pkgs.python3}/bin/python3 "
      + "${config.home.homeDirectory}/.config/aerc/mutt_oauth2.py "
      + "${config.home.homeDirectory}/.live-token";

    mbsync = safeDefaults // {
      # live.com refuses basic auth; reuse the XOAUTH2 token helper that already
      # backs this account in aerc rather than introducing a second mechanism.
      extraConfig.account = {
        AuthMechs = "XOAUTH2";
      };

      groups.live.channels = standardChannels {
        archive = "Archive";
        sent = "Sent Items";
        trash = "Deleted Items";
        junk = "Junk";
        drafts = "Drafts";
      };
    };
    notmuch.enable = true;
  };

  accounts.email.accounts.gmail = {
    mbsync = safeDefaults // {
      groups.gmail.channels = standardChannels {
        # `[Gmail]/All Mail` becomes `Archive`. This is the decision that makes
        # Gmail behave like a normal mail account instead of a label soup.
        #
        # TRADE-OFF, read before changing: individual Gmail labels are NOT synced
        # as folders. Because All Mail already contains every message, syncing
        # labels as well would mirror most messages several times over -- which
        # is the duplication that makes the current folder list unreadable.
        #
        # The cost is that label membership is not browsable as a folder tree on
        # the hub. Search still works (notmuch indexes the whole store), and any
        # specific label worth having as a real folder can be added as one more
        # channel here, e.g.:
        #   receipts = { farPattern = "Receipts"; nearPattern = "Receipts"; };
        #
        # The alternative -- sync labels, exclude All Mail -- was rejected because
        # it silently drops archived mail that carries no label.
        archive = "[Gmail]/All Mail";
        sent = "[Gmail]/Sent Mail";
        trash = "[Gmail]/Trash";
        junk = "[Gmail]/Spam";
        drafts = "[Gmail]/Drafts";
      };
    };
    notmuch.enable = true;
  };

  # ---------------------------------------------------------------------------
  # Notes for whoever turns the safety rails off
  #
  # To make deletions propagate upstream, set `expunge = "both"`. Do it one
  # account at a time, and only after message counts have been checked against
  # each provider's web UI. The intended workflow does not need it: moving a
  # message to Trash is an ordinary folder move and already syncs.
  #
  # No `home.packages` block here on purpose. `programs.mbsync` and
  # `programs.notmuch` each install their own package, so listing them again
  # would be duplication. And per `docs/architecture.md`, `home/cli.nix` owns
  # universal user-facing CLI tools -- these are hub-only machinery, not tools
  # every device should get, so they belong to neither list.
  # ---------------------------------------------------------------------------
}
