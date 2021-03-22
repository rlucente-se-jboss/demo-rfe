## Using the web console to build an image
In this lab, we'll use the web console to create a child image that
uses the contents of the image we built in the previous lab as it's
parent. The web console is a feature of RHEL 8 to simplify common
system administration tasks through a web user interface. The web
console has extensible functionality via a defined set of plugins.
For this lab, the image builder plugin has been added to the web
console.

Access the web console by browsing to `https://YOUR-HOST-NAME:9090`
and log in as a user who either has admin privileges or is a member
of the `weldr` group. For this lab, your userid is a member of the
`weldr` group so that you can use the image builder web console
features. Once you're logged in, select "Image Builder" in the
navigation bar in the left hand side.

![Image Builder](/images/image-builder.png)

You'll see information for the `RFE` blueprint file that was uploaded
in the first lab. Click the link to the right of the `RFE` blueprint
labeled `Edit Packages`. Under "Available Components", locate the
box with text "Filter by Name..." and type `strace`. Then press
ENTER.

![Filter Packages](/images/filter-packages.png)

The list of packages will be filtered to include only those with
`strace` in their name. Locate the `strace` package and then click
the "+" to the right of the package name to add it to the list of
blueprint components on the right hand side. You cannot remove the
baseline packages from an image but you can add or remove additional
packages. You are also able to specify additional package sources.
In this lab, we're only using the standard package repositories.

Select the "Commit" button to update the version number and commit
this change to the blueprint. Committing this change will automatically
increment the blueprint version number.

![Commit Change](/images/pre-commit.png)

You'll be asked to confirm that you want to commit the change so
just select "Commit" again.

In a separate terminal window, you'll need to grab the commit
identifier, the `ostree-commit` value, from the prior compose. Type
the following commands to determine the value:

    cd ~/0.0.1
    jq '.' compose.json | grep ostree-commit

Copy the hash value to the clipboard so that we can use it in the
web console when specifying the parent commit identifier when
starting a build.

In the web console, select "Create Image" to open a dialog to build
your child image.  This dialog contains several parameters to
configure the build. The "Type" parameter allows you to select from
many different image types, but for this lab please select `RHEL
for Edge Commit (.tar)`. In the "Parent commit" field, paste the
`ostree-commit` value you previously copied into the clipboard from
the prior build. Select the "Create" button to request the image
build.

![Create Image](/images/create-image.png)

Again, the build will take between five and ten minutes to complete.
Once the second image build has a status of `FINISHED`, you can
return to the terminal window to list the composed images using the
command:

    composer-cli compose status

The output will look something like this:

    149b153b-82a8-4adb-8f36-27481ac2d0f2 FINISHED Mon Dec  7 14:17:32 2020 RFE
           0.0.1 rhel-edge-commit
    12a775e4-1300-428f-a62c-505042948616 FINISHED Mon Dec  7 14:54:19 2020 RFE
           0.0.2 rhel-edge-commit 2147483648

We want to download the built image matching the `0.0.2` version.
Command line completion makes it easy to specify the correct UUID
for the desired image. In the command line below where `IMAGE_UUID`
appears, simply hit the TAB key until you see the UUID matching the
image build with version `0.0.2` above:

    mkdir -p ~/0.0.2
    cd ~/0.0.2
    composer-cli compose image IMAGE_UUID

That command will download the tarballed OSTree image and its
metadata. Extract the tarball for the image:

    tar xf  *.tar

Like before, the extracted contents have a `repo` directory for the
OSTree image and a `compose.json` file containing metadata about
the image. You can again view the `compose.json` file contents
using:

    jq '.' compose.json

You can also review the list of rpm packages included in the image
and you can confirm that the image now contains the `strace` package:

    rpm-ostree db list rhel/8/x86_64/edge --repo=repo
    rpm-ostree db list rhel/8/x86_64/edge --repo=repo | grep strace

The built image has all of the packages of its parent plus the
additional `strace` package and its dependencies. Keep in mind that
an edge device will only download the changes to its current image
and not all of the contents in order to either successfully upgrade,
or if there's a failure, seamlessly rollback to the prior image.

In the next lab, we'll use our directories to provision a RHEL for
Edge virtual guest.

