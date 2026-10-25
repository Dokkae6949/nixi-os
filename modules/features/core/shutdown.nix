{
  # Shut down within seconds instead of sitting on the 90s default per unit
  # (stacked up, that reached 2m40s). Every unit still gets SIGTERM first and
  # 15s to finish cleanly before SIGKILL; units that set their own
  # TimeoutStopSec, like those that must flush data, keep it.
  flake.modules.nixos.shutdown = {
    systemd.settings.Manager.DefaultTimeoutStopSec = "15s";
    # The per-user manager (graphical session, user services) as well.
    systemd.user.settings.Manager.DefaultTimeoutStopSec = "15s";
  };
}
