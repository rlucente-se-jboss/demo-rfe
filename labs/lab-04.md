## Install the simulated edge device
In this lab, we'll install a simulated edge device. The installation
is fully automated through a kickstart file which we'll examine in
detail while the automated install is running.  It's important to
note that the customizations in the kickstart file only apply during
the installation and only to the mutable portions of the operating
system, e.g. /var and /etc. The immutable parts of the operating
system are contained in the OSTree repository from our image build.

### Start the installation
Launch a simple web server to provide the needed kickstart file and
OSTree repository via the following commands:

    cd ~/0.0.1
    ln -s ../demo-rfe/edge.ks .
    go run ../demo-rfe/main.go

The go program runs a simple web server that counts the number of
files downloaded.

In a separate terminal window, launch the installation by running the commands:

    cd ~/demo-rfe
    ./06-launch-edge-guest.sh

The serial console is redirected to the terminal window so the edge
device installation will be fully visible while it runs.  The
installer will take some time to run as it downloads 28,160 files
for the OSTree image.

While that's running, let's take a look at the kickstart file in
detail.

### Take a look at the kickstart
Let's drill into the kickstart file to understand it's major
components and how our edge device is configured. Kickstart files
are fully described in the
[Red Hat Enterprise Linux documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/performing_an_advanced_rhel_installation/index#performing_an_automated_installation_using_kickstart)
so this discussion will focus on the parts relevant for configuring
our edge device.

A kickstart file can fully or partially automate the RHEL installation
process. They are a convenient way to specify the configuration of
the operating system, timers and services at startup, and other
customizations. Please execute the following commands in a separate
terminal window::

    cd ~/demo-rfe
    less edge.ks

Any lines beginning with `#` are comments that will be ignored
during installation. These help explain the various parts of our
kickstart file. Please scroll through the kickstart file as you
read the various section explanations below.

The initial section contains instructions on how to configure the
system installation. We won't review all of this in detail but
suffice it to say we start with empty storage and then install using
the OSTree image. Subsequent sections start and end with `%post`
and `%end`, respectively. These represent various configuration
changes to be made after the system is installed. The line before
the first `%post` section instructs the installer to use the OSTree
image during the install by specifying the URL for the OSTree content
and the image reference.

    ostreesetup --nogpg --url=http://HOST_IP_ADDRESS:8000/repo/ --osname=rhel --remote=edge --ref=rhel/8/x86_64/edge

The first `%post` section creates the home directory for our user
`core`. There is no `/home` directory on our system. The OSTree
image ensures that `/var` is not effected by atomic upgrades so
`/home` is linked to `/var/home` to preserve any customizations
across atomic upgrades. This section creates the directory
`/var/home/core` for user `core`.

The next `%post` section enables the automatic download, staging,
and updating of our edge device. First, we update the
`/etc/rpm-ostreed.conf` configuration for OSTree to automatically
stage updates to the operating system for installation at the next
system reboot. Next, we create a systemd timer and service to
periodically determine if there are staged updates and then apply
the updates by forcing a reboot. This `applyupdate.service` is run
once for each expiration of the corresponding `applyupdate.timer`
which is run once per minute. This can be customized to nearly any
period of time desired. Finally, this section enables the
`applyupdate.timer` as well as the `rpm-ostreed-automatic.timer`
whcih checks for operating system updates at the same URL supplied
during installation and then stages the updates. Together, these
files will check once per hour for updates, stage any updates, and
then trigger a reboot and upgrade within a minute of the updates
being staged. Again, you can customize or even eliminate some of
these steps, e.g. user initiated reboots only, if desired.

The following `%post` section configures a timer and service to
periodically check for updates to our example container application
and then apply the updates. The container application is launched
with `podman` via a systemd service. Podman is a daemonless container
engine for developing, managing, and running OCI Containers.
Containers can either be run as root or in rootless mode. Systemd
was selected to ensure starting the container application at boot
and automatic restarts of the container application if it should
fail.

This section takes advantage of the `podman auto-update` command
to check for more recent container images in the registry and
automatically pull the image and restart the container. This mechanism
ensures that the container applications are up to date. We first
define the `podman-auto-update.service` and then we define a systemd
timer with the same name to trigger the service once per minute.
The commented out lines in the `[Timer]` section provide an example
of how to configure this to randomly execute within a given time
window to reduce load on the system. Again, this can be customized
to nearly any period of time desired.

The `container-httpd.service` is defined in the next `%post` section.
This service definition was generated via the `podman generate
system` command. This command enables you to take a running container
and generate the needed systemd service unit file to enable starting
the container at boot time and restarting on failure. Type the
following command to see options for `podman generate systemd`:

    podman generate systemd --help

The `edge.ks` file contains the results of running that command as
a heredoc. If you examine the line starting with `ExecStart=` you'll
see the argument `--label io.containers.autoupdate=image`. This
option enables the container to be restarted by `podman auto-update`
if there's a newer image in the registry for this image repository.
Omitting this option prevents the container from being updated.

After the `container-httpd.service` definition, we configure the
list of container registries in the `/etc/containers/registries.conf`
file. The simple docker registry on the host appears under the
`[registries.insecure]` tag.

The final `%post` section defines a greenboot script to control if
an operating system upgrade succeeds or is rolled back. Greenboot
is implemented as simple shell scripts that return pass/fail results
in a prescribed directory structure. The directory structure is
shown below:

    /etc/greenboot
    +-- check
    |   +-- required.d  /* these scripts MUST succeed */
    |   +-- wanted.d    /* these scripts SHOULD succeed */
    +-- green.d         /* scripts run after success */
    +-- red.d           /* scripts run after failure */

All scripts in `required.d` must return a successful result for the
upgrade to occur. If there's a failure, the upgrade will be rolled
back. We'll force this to happen in a later lab.

Scripts within the `wanted.d` directory may succeed, but they won't
trigger a rollback of an upgrade if they fail. The `green.d` directory
contains any scripts that should run as part of a successful upgrade
and scripts in the `red.d` directory will run if there's a rollback.

The kickstart file uses a heredoc to define a simple script in
`required.d` to trigger a rollback, if desired. After system start,
the script creates a file named `/etc/greenboot/orig.txt` that
contains the OSTree commit identifier for the current image. This
file is only created if it doesn't already exist. Next, the script
writes the current OSTree commit identified to a file named
`/etc/greenboot/current.txt`. If these files are not the same, then
a rollback will occur. The default behavior is that an install and
subsequent boots will succeed, but any attempted upgrades will fail
since these files will be different. In a later lab, we'll enable
a succesful upgrade by first deleting the file `/etc/greenboot/orig.txt`,
forcing it to be written again with the latest commit identifier.

### Wait for the install to complete
When the automated install completes, the edge device will power
down. The install can take several minutes to finish.

