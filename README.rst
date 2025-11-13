Terraform Modules
=================
This repository contains our common Terraform modules. You can use any of the modules by simply
referencing the appropriate GitHub path and tag:

.. code-block:: terraform

    module "static_site" {
      source = "github.com/logikal-io/terraform-modules//gcp/gcs-static-site?ref=v1.0.0

      ...
    }

You can find more information about each module in the module-specific ``README.md`` file and learn
about the available input variables from the appropriate ``variables.tf`` file.

License
-------
The modules in this repository are licensed under the MIT open source license.
