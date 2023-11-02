# palmetto

### Palmetto Bug: (n.) A flying cockroach

(Working as of 2022-10-27)

This repo deploys CockroachDB on Fly.io.
Although Fly Machines are limited to 500gb of disk storage, Cockroach claims to be able to scale linearly and there is definitely an advantage to being able to use Fly's anycast network to connect with a single url.

## Deploying

- Install and setup flyctl if you don't already have it
  ```
  curl -L https://fly.io/install.sh | sh
  flyctl auth login
  ```
- Clone the repo
  ```
  git clone https://github.com/kahnpoint/palmetto
  cd palmetto
  ```
- Change the app name in the `fly.toml` file to something unique
- Change `.env.example` to `.env` and fill in the values.
  - `PALMETTO_APP_NAME` should match the app name in `fly.toml`.
  - `PALMETTO_WEBHOOK_URL` is an optional Discord webhook url, and can be tested by running `bash .sh/dev/test-webhook.sh`
- Install the CockroachDB binary locally (this is used to generate the root certs)
  ```
  bash .sh/dev/crdb-install-binary.sh
  ```
- Generate Cockroachdb certs 
  ```
  source .sh/dev/crdb-create-ca.sh -r -u
  ```
  - the -r flag regenerates the certs 
  - the -u flag uploads them to Fly as secrets
- Deploy the app
  ```
  bash .sh/fly/deploy.sh
  ```
  - If it complains about needing a volume, just run it again
- The first node in the cluster will bootstrap itself. This can take a couple minutes. You can check the status at https://fly.io/apps/$PALMETTO_APP_NAME/monitoring or with
  ```
  flyctl status
  ```
- When it's finished, proxy the ports to your local machine with
  ```
  bash .sh/fly/proxy.sh
  ```
- Visit the console at http://localhost:8080 and log in with username "server" and the password you set in the `.env` file.
  - The default behavior of this setup is to only allow connections from other Fly apps within the same organization. If you need to connect from outside the Fly network, you can either proxy it as shown above or add external ports to the `fly.toml` (not recommended).
  - To test the internal networking, you can use the `palmetto-test` folder (you will likely need to change the name again) which deploys a dummy vm with cockroachdb installed.
    ```
    cd palmetto-test
    bash .sh/deploy.sh
    flyctl ssh console
    ```
  - Then, connect to "palmetto" from the "palmetto-test" ssh console with
    ```
    cockroach sql --insecure --host=palmetto.internal:5432
    ```
  - Now you should be able to run `SHOW DATABASES;` to check that it's working.
  - Don't forget to tear it down when you're done:
    ```
    flyctl apps destroy palmetto-test
    ```
- After the first node is up, you can add more nodes to the cluster. They will automatically join, and nodes in different regions will geopartition the data correctly. You can see all the available regions with `flyctl platform regions`.
  ```
  flyctl scale count 1 --region cdg # France
  flyctl scale count 1 --region nrt # Japan
  ```
  -  After running the 2 commands above, after a few minutes, you should be able to see "Live Nodes = 3" in the dashboard, with the updated capacity.
- You now have a globally-distributed infintely-scaleable postgres-compatible database. Have fun!
