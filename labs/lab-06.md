In this lab, we'll show how RHEL for Edge simplifies operating
system upgrades and automates rollbacks when upgrades fail. We'll
also look at the greenboot facility that enables applications to
define the conditions necessary for a successful upgrade.  Again,
we're using QEMU to emulate the device in user space to simplify
demonstrating the various edge features, and we're specifically not
leveraging either virtualization or separate edge devices. All of
this content can certainly work in those environments as well.

To deliver updated OSTree content, we need to have a running web
server. In this lab, we'll use a simple web server on the host to
serve the OSTree content to the guest. Type the following commands
in a host terminal to start the web server in the same directory
as the updated OSTree content:

    cd ~/0.0.2
    go run ../demo-rfe/main.go

Please start an edge guest in a separate terminal on the host if
you don't already have a running guest. This will serve at the guest
terminal when needed for additional commands below. Type the following
commands in a host terminal to launch the edge guest:

    ./07-launch-edge-guest.sh

As discussed in a previous lab, greenboot is implemented as simple
shell scripts that return pass/fail results in a prescribed directory
structure. The directory structure is shown below:

    /etc/greenboot
    +-- check
    |   +-- required.d  /* these scripts MUST succeed */
    |   +-- wanted.d    /* these scripts SHOULD succeed */
    +-- green.d         /* scripts run after success */
    +-- red.d           /* scripts run after failure */

All scripts in `required.d` must return a successful result for the
upgrade to occur. If there's a failure, the upgrade will be rolled
back. This lab will leverage a script to force a rollback to occur.

Scripts within the `wanted.d` directory may succeed, but they won't
trigger a rollback of an upgrade if they fail. The `green.d` directory
contains scripts that should run as part of a successful upgrade
and scripts in the `red.d` directory will run if there's a rollback.

The simple shell script at
`/etc/greenboot/check/required.d/01_check_upgrade.sh` will fail if
the files `orig.txt` and `current.txt` differ. These files hold the
OSTree commit identifier after initial boot and the OSTree commit
identifier for the current boot. Type the following commands in a
guest terminal window to review the current OSTree commit identifier
and the contents of those files:

    cd /etc/greenboot
    rpm-ostree status -v
    cat orig.txt current.txt

The text files hold the same OSTree commit identifier that's currently
active. We'll use this simple mechanism, for demonstration purposes,
to control if an upgrade succeeds or rolls back. By default, an
attempted upgrade will fail since the file `orig.txt` will not match
the new OSTree commit identifier in `current.txt`.

The edge device has two systemd services, triggered by configurable
timers, to stage new OSTree images and force a reboot to trigger
an upgrade. The `rpm-ostreed-automatic` service downloads and stages
OSTree image content. The timer for this service is triggered once
an hour per the corresponding timer configuration. Systemd timers
are incredibly flexible and can be configured for virtually any
schedule. The `applyupdate` service triggers a reboot when there
is staged OSTree image content. The timer for this service is
triggered once per minute to automate upgrades for this demonstration.
Again, nearly any schedule can be used for this timer.

Type the following command in a guest terminal to view when these
timers are set to be triggered.

    systemctl list-timers | grep -E 'rpm|apply'

The output will resemble the following:

    Fri 2021-04-02 18:11:32 UTC  56s left      Fri 2021-04-02 18:10:32 UTC  3s ago applyupdate.timer
    Fri 2021-04-02 18:59:11 UTC  48min left    n/a                          n/a    rpm-ostreed-automatic.timer

Rather than wait up to an hour for the `rpm-ostreed-automatic`
service to be triggered via its timer, we'll instead force an upgrade
by directly running the service. Type the following command in the
guest terminal window:

    sudo systemctl start rpm-ostreed-automatic

This will start the process on the guest edge device to pull new
content from the host. In the host terminal, you'll see the various
files being downloaded to the the guest. You should also notice
that the number of files and their accumulative size is much smaller
than the initial installation. This is because rpm-ostree only
downloads the deltas between the current OSTree image and the new
OSTree image which can save significant bandwidth and time when
operating in environments with limited connectivity.

After the content is downloaded and staged, the `applyupdate` timer
will expire within a minute and start the `applyupdate` service
that will trigger a reboot.

Since the `/etc/greenboot/orig.txt` file contains the OSTree commit identifier from the initial installation, any successive upgrade will fail. The system will attempt to upgrade the operating system three times before rolling back to the prior version. With each boot attempt, you should see the following appear in the guest terminal:

      Red Hat Enterprise Linux 8.3 (Ootpa) (ostree:0)
      Red Hat Enterprise Linux 8.3 (Ootpa) (ostree:1)

The `ostree:0` image will be highlighted on the first three boot
attempts since `ostree:0` designates the most recent operating
system content and `ostree:1` represents the previous operating
system content. After the third failed attempt, the guest terminal
will then highlight `ostree:1` which indicates that a roll back is
occurring to the prior image. This entire process will take a few
minutes to complete.

When the rollback is completed, the login prompt will appear in the guest terminal. Login using username `core` and password `edge`. Type the following command to confirm that the upgrade did not occur by looking at the current commit identifiers of the local operating system content:

    rpm-ostree status -v

The output from that command will resemble the following:

    State: idle
    AutomaticUpdates: stage; rpm-ostreed-automatic.timer: no runs since boot
    Deployments:
    * ostree://edge:rhel/8/x86_64/edge
                     Timestamp: 2021-03-31T00:11:31Z
                        Commit: 98a1d03316797162d4b3a1fad22c36be049c46b42605307a0553e35c909c6a6d
                        Staged: no
                     StateRoot: rhel
    
      ostree://edge:rhel/8/x86_64/edge
                     Timestamp: 2021-03-31T00:38:20Z
                        Commit: 662c26c39800e4fa97430fecdab6d25bd704c8d9228555e082217b16d5697f02
                     StateRoot: rhel

The active image is preceded with an `*` and you can tell its the
prior image by looking at the timestamps for both. The commit
identifier for the active image also matches the commit identifiers
in both the `/etc/greenboot/orig.txt` and `/etc/greenboot/current.txt`
files. Type the following commands to exxamine those files.

    cd /etc/greenboot
    cat orig.txt current.txt

When we built the `0.0.2` version of our operating system OSTree
image, we added the `strace` utility. You can confirm that utility
is missing in the current active operating system image by typing
the following command in the guest terminal:

    which strace

The output should resemble the following:

    /usr/bin/which: no strace in (/usr/local/bin:/usr/bin:/usr/local/sbin:/usr/sbin)

Now, let's enable the OSTree upgrade to occur by deleting the
`/etc/greenboot/orig.txt` file so that our greenboot script at
`/etc/greenboot/check/required.d/01-check_upgrade.sh` returns
success, allowing the upgrade process to move forward. In the guest
terminal, type the following command:

    sudo rm -f orig.txt

We need to stage new OSTree content for the upgrade, so we'll re-run the `rpm-ostreed-automatic` service to download and stage the content from the web server on the host. Please type the following command in the guest terminal:

    sudo systemctl start rpm-ostreed-automatic

You'll observe in the host terminal that only five files are requested
of inconsequential size. The guest already has the content needed
so it's merely requesting metadata to determine if this is the most
recent OSTree content. Once the content is staged, the `applyupdate`
service timer will expire within a minute and the `applyupdate`
service will trigger a reboot. You can see the amount of time
remaining for that timer by typing the following command in the
guest terminal:

    systemctl list-timers | grep applyupdate

The reboot will be triggered and the upgrade will succeed this time.
The boot screen with the OSTree image list will appear only nce.
This will take a minute or two to finish. Once the login prompt
appears, login again as user `core` with password `edge`. Confirm
that the upgrade was successful by seeing that the `strace` command
is available by typing the following command in the guest terminal:

    which strace

The output should resemble:

    /usr/bin/strace

You can also examine the OSTree image list to see that the newest
OSTree image content is active.

    rpm-ostree status -v

The output from that command will resemble:

    State: idle
    AutomaticUpdates: stage; rpm-ostreed-automatic.timer: no runs since boot
    Deployments:
    * ostree://edge:rhel/8/x86_64/edge
                     Timestamp: 2021-03-31T00:38:20Z
                        Commit: 662c26c39800e4fa97430fecdab6d25bd704c8d9228555e082217b16d5697f02
                        Staged: no
                     StateRoot: rhel
    
      ostree://edge:rhel/8/x86_64/edge
                     Timestamp: 2021-03-31T00:11:31Z
                        Commit: 98a1d03316797162d4b3a1fad22c36be049c46b42605307a0553e35c909c6a6d
                     StateRoot: rhel

To terminate the emulated edge device, simply type the following
command in the guest terminal window:

    sudo poweroff

This completes the RHEL for Edge workshop. In this workshop you
were able to create both a parent and child OSTree image for your
edge device using the command line tool and web interface; install
an edge device using the OSTree content; automatically restart and
upgrade container applications running on the edge device; and both
rollback and upgrade the OSTree content on the edge device.

