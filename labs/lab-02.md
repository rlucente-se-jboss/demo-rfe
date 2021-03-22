## Using composer-cli to build an image
RHEL for Edge provides an image-builder backend, accessed through
a REST API with both command line tooling and web console interfaces.
This lab walks you through building your first image with the
`composer-cli` command line tool.

### Building your first image
The `composer-cli` tool takes several parameters to begin building
an image. You'll need to specify, at a minimum, the blueprint and
the image type. Use the following command To see a list of available
types:

    composer-cli compose types

A `compose` represents an individual build of a system image, based
on a particular version of a particular blueprint. Compose as a
term refers to the system image, the logs from its creation, inputs,
metadata, and the process itself. This lab builds an rpm-ostree
image which corresponds to the `rhel-edge-commit` image type.

Submit an image build to the image builder backend using:

    composer-cli compose start RFE rhel-edge-commit

The command will return a build ID for the compose and add it to
the build queue. The image will take between five and ten minutes
to build. You can check the status using:

    composer-cli compose status

Each status line contains several fields:

* build id
* status which is `RUNNING` for in-process builds and `FINISHED` for completed builds
* date and time the build was started, for running builds, and completed, for finished builds
* blueprint name
* blueprint version
* image type.

Wait until the image has a status of FINISHED, then create a directory
to hold the expanded content.  We'll use this directory to examine
the image contents and also offer the image and other needed
information to enable a RHEL for Edge installation to a target
system.

    mkdir -p ~/0.0.1
    cd ~/0.0.1

The `composer-cli` command can be used to download a built image.
You can use commandline completion by just pressing the TAB key to
make the appropriate build ID appear in the below `composer-cli`
command.

    composer-cli compose image BUILD_ID

The downloaded image format is a tarball containing an OSTree
repository. The OSTree repository contains a commit and a `compose.json`
metadata file. You can expand the contents of the tarball using:

    tar xf *.tar

Use the `jq` tool to reformat the `compose.json` metadata file to
make it more human-readable.

    jq '.' compose.json

Review the JSON file contents. You'll notice values for the reference
ID, `ref`, and the commit ID, `ostree-commit`. The commit ID uniquely
identifies the image. You can also find this value in the file at
`repo/refs/heads/rhel/8/x86_64/edge` where the last four components
of that path match the reference ID.

The OSTree repository is not human-readable. Use the following
command To see the list of RPM packages included in the image:

    rpm-ostree db list rhel/8/x86_64/edge --repo=repo | less

The list of packages is quite long and it is based on all the
packages discussed in the previous lab. You'll notice that we're
pulling the list of packages for the specified reference ID
`rhel/8/x86_64/edge`.

In the next lab, the commit ID, `ostree-commit`, will be used with
the web console tooling to create another OSTree image that is the
child of this one.

