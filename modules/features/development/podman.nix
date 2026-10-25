{
  flake.modules.nixos.podman.virtualisation.podman = {
    enable = true;

    # `docker` CLI and /var/run/docker.sock backed by Podman, so tools that
    # expect Docker (compose, testcontainers, IDEs) keep working.
    dockerCompat = true;
    dockerSocket.enable = true;
  };
}
