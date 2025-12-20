# Restarting Cloudflare Tunnel Connector

Your connector is showing as "Inactive" in the dashboard. Here's how to fix it:

## Step 1: Get Fresh Token from Dashboard

1. Go to **Cloudflare Dashboard** → **Zero Trust** → **Tunnels**
2. Click on your tunnel
3. Look for **"Configure"** or **"Quick Start"** button
4. You'll see a command that looks like:
   ```bash
   cloudflared tunnel --token eyJhIjoi...
   ```
5. **Copy that entire command**

## Step 2: Run the Command

Run the command you copied from the dashboard. It will start the connector and connect it to Cloudflare.

**Important**: Keep this terminal/process running! The connector needs to stay running to maintain the connection.

## Step 3: Verify Connection

1. Go back to dashboard → **Zero Trust** → **Tunnels** → Your tunnel
2. Check the **"Connectors"** section
3. Should show **"Connected"** status (not "Inactive")

## Step 4: Test

Once it shows "Connected", wait 30 seconds, then test:
```bash
curl https://enjoyyy.mmmmichael.com/
```

## Running in Background (Optional)

If you want to run it in the background:

```bash
# Run in background
nohup cloudflared tunnel --token [YOUR-TOKEN] > /tmp/cloudflared.log 2>&1 &

# Or use screen/tmux
screen -S tunnel
# Then run the command
# Press Ctrl+A then D to detach
```

## Troubleshooting

If it still shows "Inactive":
- Make sure you copied the ENTIRE token (it's very long)
- Check if there are any errors: `tail -f /tmp/cloudflared.log`
- Try stopping and starting again
- Verify your tunnel ID matches in the dashboard

