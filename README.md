# Palmetto
### (n.) A flying cockroach

(Working as of 2024-03-06)

This repo deploys CockroachDB on Fly.io. Features include:
  - Automatic S3 backups
  - Geopartitioning
  - Geospatial libraries
  - Certificate management
  - Support for multiple environments (dev/prod/etc.)
  - Utilities for generating connection strings, backup URLs, and local proxies

## Setup

- Install and setup flyctl if you don't already have it
  ```bash
  curl -L https://fly.io/install.sh | sh
  flyctl auth login
  ```
  
- Clone the repo
  ```bash
  git clone https://github.com/mootline/palmetto
  cd palmetto
  ```

- Setup the project with `bash .sh/dev/setup.sh` 
  - This will download the CockroachDB binary (for generating certs) and create the `.env` file.
  - Fill in the `.env` values, and be sure to change the app name to something unique.

## Deployment

- Create the Fly app with `bash .sh/fly/create-fly-app.sh dev`.
  - This will create a new app for each environment argument. For example, you can use `bash .sh/fly/create-fly-app.sh prod` to create a seperate app for production.
  
- Generate the CockroachDB root certs with `bash .sh/dev/crdb-create-ca.sh dev -r -s`
  - The -r flag regenerates the certs
  - The -s flag syncs the certs as secrets to the Fly app

- Deploy the app with `bash .sh/fly/deploy.sh dev -s`
  - If it complains about needing a volume, just run it again
  - The -s flag will sync the required secrets to the Fly app.
  - The first node in the cluster will bootstrap itself. This can take a couple minutes. You can check the status at https://fly.io/apps/$PALMETTO_APP_NAME/monitoring or with `flyctl status`.
  
- When it's finished, proxy the ports to your local machine with `bash .sh/fly/proxy.sh`

  - Visit the console at https://localhost:8080 and log in with the username and password you set in the `.env` file.
    - Your browser will probably complain about the certificate. This is expected behavior, as the certificate is self-signed. You can ignore the warning and proceed to the site.
  - The default behavior of this setup is to only allow connections from other Fly apps within the same organization. 
    - If you need to connect from outside the Fly network, you can either proxy it as shown above or add external ports to the `fly.toml.template` (not recommended).

- After the first node is up, you can add more nodes to the cluster. They will automatically join, and nodes in different regions will geopartition the data correctly. You can see all the available regions with `flyctl platform regions`.
  ```
  flyctl scale count 1 --region cdg # France
  flyctl scale count 1 --region nrt # Japan
  ```
  -  After running the 2 commands above, after a few minutes, you should be able to see "Live Nodes = 3" in the dashboard, with the updated capacity.
    - The list of nodes will also change from displaying the internal IP to the region name.
  
- You now have a globally-distributed infinitely-scaleable Postgres-compatible database. 🥳

## Utilities
- `.sh/dev/postgres-url.sh`
  - Generates the postgres URL for connecting to the database
  - By default generates the localhost one, for use when proxying the ports to your local machine.
  - `.sh/dev/postgres-url.sh dev` generates the internal Fly URL, for use when connecting from another Fly app.
- `.sh/dev/s3-url.sh` 
  - Generates the S3 backup URL
  - Cockroach uses `AWS_REGION` and `AWS_ENDPOINT` instead of `REGION` and `ENDPOINT` like some other services, so you may need to adjust the URL if you use it for something else.
  

## Disaster Recovery
- Palmetto does daily full backups to S3 (recommended by CockroachDB for production use).
  - Restores are highly unlikely, but hey, sometimes you need them.
  - Note: Restores should be done with the same version of cockroach as the backup was made with.
- Performing a restore
  - Get your s3 backup URL with `.sh/dev/s3-url.sh`
  - SSH into a node on the cluster you want to restore into with `flyctl ssh console -a $PALMETTO_APP_NAME`
    - This will destroy the current data in the cluster.
    - You will need to drop any existing databases before restoring. If you run the command, it will tell you which ones need to be dropped.
  - Fill out the following command and run it in the SSH session 
    - ```bash
    cockroach sql --certs-dir "/palmetto-dev-data-mount/cockroach-certs" --execute "RESTORE FROM LATEST IN ${PALMETTO_S3_BACKUP_URL};"
    ```
  - If you ever need to force a backup to run immediately, run 
    - ```bash
    cockroach sql --certs-dir "/palmetto-dev-data-mount/cockroach-certs" --execute "BACKUP INTO ${PALMETTO_S3_BACKUP_URL};"
    ```