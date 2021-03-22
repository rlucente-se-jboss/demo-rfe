## Defining your image blueprint
In this lab, we'll define the contents of your operating system
image.  This definition is codified in a blueprint file which follows
[Tom's Obvious Minimal Language](https://toml.io/en/) (TOML)
formatting. Let's take a look at an example file in your local
directory. In your terminal window, type the following commands:

    cd ~/demo-rfe
    cat RFE.toml

The [blueprint reference](https://weldr.io/lorax/composer-cli.html#blueprint-reference)
describes the various table headers and key/value pairs. This file
resembles the familiar INI file format.  The blueprint contains
several important sections. At the top is the meta-data definition
for this image including the `name`, `description`, and `version`
which is shown in this snippet:

    name = "RFE"
    description = "RHEL for Edge"
    version = "0.0.1"

The remaining entries define the contents of the operating system
image. For example, `packages` is currently empty, however this
entity can be repeated to describe the list of packages to be added
to the default minimal set included in the image. These package
table headers can appear multiple times in the blueprint file, with
each entry formatted as shown here:

    [[packages]]
    name = "strace"
    version = "*"

The double square brackets, `[[` and `]]`, indicate an entity that
can appear more than once.  The `*` indicates to include all versions
of the package in the generated image. Our example file includes
no additional packages, modules, or groups at this time.

The next section describes customizations to the generated operating
system image. TCP port 8080 is being opened since the image will
host a web server, and a user with administrator privileges is also
defined. A hashed password is included in the file, but you can
also use a plaintext value.

Operating system images output by image-builder contain a defined
[set of packages](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/composing_a_customized_rhel_system_image/index#packages-installed-by-default_creating-system-images-with-composer-command-line-interface)
based on the image type being generated. You can view all the
packages in the `comps core` group using:

    sudo dnf group info --hidden Core | less

You'll see several categories of packages, including mandatory,
default, and optional. Image builder includes packages from both
the mandatory and default categories (see the
[blueprint reference](https://weldr.io/lorax/composer-cli.html#groups)
for more information) and supplements them with the listed packages
by image type.

Let's use the `composer-cli` command to push the blueprint file to
the image builder server using the following command:

    composer-cli blueprints push RFE.toml

Confirm that the blueprint was uploaded by listing all blueprints
on the server:

    composer-cli blueprints list

Also, confirm the contents of the uploaded blueprint using:

    composer-cli blueprints show RFE

For a full list of all blueprint commands, type the following:

    composer-cli blueprints help

You'll see a list of all of the blueprint commands with a short
description of each command and its arguments.

In the next lab, you'll use this blueprint to build an image.

