# RHEL for Edge Demo
This presents a demonstration of RHEL for Edge that includes:
* atomic upgrade of the underlying operating system
* greenboot to control whether the atomic upgrade succeeds
* hosting container workloads that can be independently updated

## Setup 
Start with a minimal install of RHEL 8.3+. Make sure this repository
is on the host using either `git` or `scp` this directly.  Download the
[RHEL 8.3 Boot ISO](https://access.redhat.com/downloads/content/479/ver=/rhel---8/8.3/x86_64/product-software)
and make sure that you
also have an RPM of the [full build of QEMU](https://github.com/ajacocks/qemu)
in the same directory as this repository.

You'll need to customize the settings in the `demo.conf` script to
include your Red Hat Subscription Manager (RHSM) credentials to
login to the [customer support portal](https://access.redhat.com)
to pull updated content. Also, review the settings for the amount
of memory (in MiB), disk size, and guest SLiRP network IP address
range for the RHEL for Edge guest.  Please make sure the path to the
[RHEL 8.3 boot ISO](https://access.redhat.com/downloads/content/479/ver=/rhel---8/8.3/x86_64/product-software) is correct.

Run the following scripts to prepare the demo environment.

    cd ~/demo-rfe
    sudo ./01-setup-rhel8.sh
    reboot
    sudo ./02-config-image-builder.sh
    sudo ./03-config-registry.sh
    ./04-build-containers.sh
    sudo ./05-install-qemu.sh

The above scripts do the following:
* subscribe to Red Hat for updates
* install and enable the web console and image builder
* enable a local insecure registry on the host
* build two versions of a container app and push both to the local registry
* install the full version of QEMU

## Compose the os-tree images
Next, use the `composer-cli` tool to create the initial os-tree
repository. Inspect the provided blueprint file which defines a
default user and enables port 8080 in the firewall.

    cat RFE.toml

Next, push the blueprint file to the image builder server:

    composer-cli blueprints push RFE.toml

Launch an image build:

    composer-cli compose start RFE rhel-edge-commit

The image will take between five and ten minutes to build. You can
check the status using:

    composer-cli compose status

When the image has a status of FINISHED, create a directory to hold
the expanded content as well as the needed kickstart file. Use
command completion by just pressing the TAB key to make the appropriate
IMAGE_UUID appear in the below `composer-cli` command.

    mkdir -p ~/0.0.1
    cd ~/0.0.1
    composer-cli compose image IMAGE_UUID

Link the `edge.ks` file to the new directory and extract the tar
file for the image.

    ln -s ../demo-rfe/edge.ks .
    tar xf  *.tar

After the content is expanded, the directory will have a `compose.json`
file in addition to the ostree repository. Review the JSON file and
copy the `ostree-commit` value to the clipboard. You'll use that
when creating an image derived from this one in the web console.

    jq '.' compose.json

The list of rpm packages included in the commit can be listed via:

    rpm-ostree db list rhel/8/x86_64/edge --repo=repo

Create the second image using the web console. Browse to
`https://YOUR-HOST-NAME:9090` and log in as a user with admin
privileges (or at least a member of the `weldr` group). Once you're
logged in, select "Image Builder" in the navigation bar in the left
hand side.

![Image Builder](/images/image-builder.png)

Click the link to the right of the `RFE` blueprint labeled `Edit
Packages`. Under "Available Components", type `strace` in the box
with text "Filter By Name..." and then press ENTER.

![Filter Packages](/images/filter-packages.png)

Click the "+" to the right of the `strace` package to add it to the
blueprint components on the right hand side. Select the "Commit"
button to update the version number and commit this change to the
blueprint.

![Commit Change](/images/pre-commit.png)

You'll be asked to confirm the commit so just select "Commit" again.
Next, select "Create Image" to kickoff a build of the image. In the
dialog, select `RHEL for Edge Commit (.tar)` for the Type field and
paste the `ostree-commit` value you copied into the clipboard into
the Parent commit field. Select the "Create" button to kick off the
image build.

![Create Image](/images/create-image.png)

The build will take between five and ten minutes to complete. Once
it's finished, list the image UUIDs on the command line using:

    composer-cli compose status

The output will look something like this:

    149b153b-82a8-4adb-8f36-27481ac2d0f2 FINISHED Mon Dec  7 14:17:32 2020 RFE
           0.0.1 rhel-edge-commit
    12a775e4-1300-428f-a62c-505042948616 FINISHED Mon Dec  7 14:54:19 2020 RFE
           0.0.2 rhel-edge-commit 2147483648

We want to work with the UUID matching the `0.0.2` version of the
image build. For the `composer-cli compose image` command below,
use command completion by just pressing the TAB key and selecting
the UUID matching version `0.0.2` as shown above.

    mkdir -p ~/0.0.2
    cd ~/0.0.2
    composer-cli compose image IMAGE_UUID

Link the `edge.ks` file to the new directory and extract the tar
file for the image.

    ln -s ../demo-rfe/edge.ks .
    tar xf  *.tar

The list of rpm packages included in the commit can be listed via:

    rpm-ostree db list rhel/8/x86_64/edge --repo=repo

## Demo
You're now ready to demonstrate this capability. On the server where
you've built the images, go to the 0.0.1 folder which holds the initial
build and run a simple web server to offer that content to clients:

    cd ~/0.0.1
    go run ../demo-rfe/main.go

Edit your `$HOME/.bashrc` file and add the following stanza:

    if ! [[ "$PATH" =~ "/opt/qemu-5.2.0/bin:" ]]
    then
        PATH="/opt/qemu-5.2.0/bin:$PATH"
    fi
    export PATH

Launch a separate terminal and then create a RHEL for Edge guest VM.

    cd ~/demo-rfe
    ./06-install-edge-guest.sh

TODO ...

