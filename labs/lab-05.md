In this lab, we'll show how the combination of systemd and podman
enables automated restarts and upgrades of container applications
in a small footprint environment. We're using QEMU to emulate the
device in user space to simplify demonstrating the various edge
features, and we're specifically not leveraging either virtualization
or separate edge devices. All of this content can certainly work
in those environments as well.

To begin, we'll relaunch our recently installed edge device. The
included bash script takes care of the various command line options
for QEMU. Feel free to review the script prior to running it. In a
host terminal, issue the commands:

    cd ~/demo-rfe
    less 07-launch-edge-guest.sh

Please start an edge guest in the same terminal. This terminal will
serve at the guest terminal when needed for additional commands
below. Type the following commands in the host terminal to launch
the edge guest:

    ./07-launch-edge-guest.sh

The serial console output for the edge device is redirected to the
terminal so you can observe all of the boot output. When the system
login prompt appears, log into the emulated edge guest using username
`core` and password `edge`.

The edge device has a simple container web application that returns
static content. You'll need to confirm that the container application
has fully started. In the same terminal, type the following commands
to see if the container web application is fully active.

    systemctl status container-httpd.service
    sudo watch -n 5 podman container list

After the container is fully started, the `watch` command will
produce output similar to the following:

    Every 5.0s: podman container...  localhost.localdomain: Fri Apr  2 17:21:19 2021
    
    CONTAINER ID  IMAGE                         COMMAND               CREATED
     STATUS            PORTS                 NAMES
    64c18d270b65  192.168.76.2:5000/httpd:prod  /usr/sbin/httpd -...  3 minutes ago
     Up 3 minutes ago  0.0.0.0:8080->80/tcp  httpd

In the terminal, press the key combination `CTRL-C` to terminate
the `watch` command after the container is fully started.

The systemd configuration for our container web service has the
policy `Restart=on-failure`. If the program should unexpectedly
fail, systemd will restart it. However, if the program normally
exits, it will not be restarted. The policy can also be modified
to cover many use cases as we'll see in a minute. Let's go ahead
and trigger a restart of our container web application. In the
terminal, type the following command:

    sudo pkill -9 httpd

This command sends a KILL signal to the httpd processes inside the
container, immediately terminating them. Since the restart policy
is `on-failure`, systemd will relaunch the container web application.
While that's happening, we can discuss the various restart policies
that are available.

The table below lists how the various policies affect a restart.
The left-most column lists the various causes for why the systemd
managed service exited. The top row lists the various restart
policies. And the `X`'s indicate whether a restart will occur for
each combination of exit reason and policy. A full discussion of
the `Restart=` option in the systemd service unit file is available
via the command `man systemd-unit` on the host system (the guest
has no man pages installed to reduce space).

 Restart settings/Exit causes | no | always | on-success | on-failure | on-abnormal | on-abort | on-watchdog 
------------------------------|----|--------|------------|------------|-------------|----------|-------------
 Clean exit code or signal    |    |   X    |     X      |            |             |          |             
 Unclean exit code            |    |   X    |            |     X      |             |          |             
 Unclean signal               |    |   X    |            |     X      |     X       |    X     |             
 Timeout                      |    |   X    |            |     X      |     X       |          |             
 Watchdog                     |    |   X    |            |     X      |     X       |          |     X       

Once again, please confirm that the container application has fully
started. In the same terminal, type the following commands to see
if the container web application is fully active.

    systemctl status container-httpd.service
    sudo watch -n 5 podman container list

In the guest terminal, press the key combination `CTRL-C` to terminate
the `watch` command after the container is fully started.

Next, let's take a look at how `podman auto-update` can ensure that
we're running the most up-to-date version of our container application.
We'll begin by examining the contents returned by the current
container web application. In the same guest terminal, type the
following command:

    curl http://localhost:8080

The output from that command should look like the following:

    Welcome to RHEL for Edge!

Let's take a look at which container image our container web
application is using. This application was defined to launch at
boot time and runs as root. To list the container images, please
type the following command in the guest terminal:

    sudo podman images

The output lists the repository, tag, image identifier, when the
image was created, and it's size. The image identifier is the first
twelve characters of a much longer hash value for the image.

    REPOSITORY               TAG     IMAGE ID      CREATED     SIZE
    192.168.76.2:5000/httpd  prod    5685cd3533b3  2 days ago  353 MB

To upgrade our container web application we're first going to move
the `prod` tag a newer image within the `httpd` image repository.
In the host terminal, please type the following commands:

    podman pull --all-tags 192.168.76.2:5000/httpd
    podman images

The first command pulls down all the tags for the `httpd` image
repository. The second command then lists those images. The output
will look similar to the following:

    REPOSITORY                           TAG     IMAGE ID      CREATED      SIZE
    192.168.76.2:5000/httpd              v2      b87c1cc49c30  5 days ago   353 MB
    192.168.76.2:5000/httpd              v1      5685cd3533b3  5 days ago   353 MB
    192.168.76.2:5000/httpd              prod    5685cd3533b3  5 days ago   353 MB
    registry.access.redhat.com/ubi8/ubi  latest  4199acc83c6a  7 weeks ago  213 MB

The `v1` and `v2` tags are used to discriminate between the two
versions of the container web application. Currently, the `prod`
tag points to the `v1` tag, so the running instance matches the
first version. Take note of the `IMAGE ID` for the `v2` tag as we'll
look at that later.

We can change the `prod` tag to match the second version of the
container web application. To do so, type the following commands:

    podman tag 192.168.76.2:5000/httpd:v2 192.168.76.2:5000/httpd:prod
    podman push 192.168.76.2:5000/httpd:prod

The first command assigns the `prod` tag to the same image that's
assigned the `v2` tag. The second command pushes the changes to the
image registry.

The guest edge device has a service we discussed in a previous lab
that automatically updates container applications if there's a
different image in the registry than the container that's currently
running. This is through the `podman auto-update` command that
checks the external registry, if it's available. If the hash of the
container image in the registry differs from the hash of the currently
running image, `podman` pulls the newest image and then restarts
the container application.

List the current set of timers on the guest to see when the
`podman-auto-update.timer` expires. This timer triggers the
`podman-auto-update.service` to pull the latest container image and
restart the container web application. This timer is currently
configured to expire every minute.

    systemctl list-timers | grep podman

The container web application is pulling the image with the `prod`
tag. Since we just changed, you should see the restart occur. Please
confirm that the container application has fully started. In the
guest terminal, type the following commands to see if the container
web application is fully active.

    systemctl status container-httpd.service
    sudo watch -n 5 podman container list

In the guest terminal, press the key combination `CTRL-C` to terminate
the `watch` command after the container is fully started.

List the images to verify that the the image with the `prod` tag
now matches the `IMAGE ID` that was with the `v2` tag. Type the
following command in the guest terminal:

    sudo podman images

The output will resemble the following where the `IMAGE ID` below
matches the `IMAGE ID` for `v2` in the host terminal from earlier.

    REPOSITORY               TAG     IMAGE ID      CREATED     SIZE
    192.168.76.2:5000/httpd  prod    b87c1cc49c30  2 days ago  353 MB

With the container web application restarted with the new container
image, we can now test the application to Verify that the output
has changed with the new version:

    curl http://localhost:8080

The output should resemble the following:

    Welcome to RHEL for Edge!
    Podman auto-update is awesome!

In this lab, we saw how systemd and podman enables automated restarts
of container applications and simplified upgrades via `podman
auto-update`. In the next lab, we'll take a look at how RHEL for
Edge simplifies operating system upgrades and rollbacks when the
upgrade fails.

