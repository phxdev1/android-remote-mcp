// Additional code to add to server.js for Docker integration

// Import additional modules if needed
const os = require('os');

// Function to get Tailscale IP address
function getTailscaleIP() {
  // First check environment variable set by init.sh
  if (process.env.TAILSCALE_IP) {
    return process.env.TAILSCALE_IP;
  }
  
  // Otherwise try to find by network interface
  const interfaces = os.networkInterfaces();
  for (const name of Object.keys(interfaces)) {
    if (name.includes('tailscale') || name.includes('ts')) {
      const iface = interfaces[name].find(i => i.family === 'IPv4');
      if (iface) {
        return iface.address;
      }
    }
  }
  
  // Fallback
  return '100.x.y.z'; // Placeholder - will be replaced with actual
}

// Add Docker-specific endpoints
app.get('/status', (req, res) => {
  const tailscaleIP = getTailscaleIP();
  const adbDevices = [];
  
  try {
    const devices = execSync('adb devices').toString();
    const connectedDevices = devices
      .split('\n')
      .filter(line => line.includes('\t'))
      .map(line => {
        const parts = line.split('\t');
        const ipWithPort = parts[0];
        const status = parts[1].trim();
        return { device: ipWithPort, status };
      });
    
    adbDevices.push(...connectedDevices);
  } catch (error) {
    console.error('Error getting ADB devices:', error);
  }
  
  res.json({
    status: 'running',
    tailscale: {
      connected: !!tailscaleIP,
      ip: tailscaleIP
    },
    adb: {
      devices: adbDevices,
      count: adbDevices.length
    },
    server: {
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      node: process.version
    }
  });
});

// Add Tailscale utility endpoint
app.get('/tailscale/status', (req, res) => {
  try {
    const status = execSync('tailscale status --json').toString();
    res.type('json').send(status);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add ADB utility endpoints
app.post('/adb/restart', (req, res) => {
  try {
    execSync('adb kill-server');
    setTimeout(() => {
      execSync('adb start-server');
      res.json({ success: true, message: 'ADB server restarted' });
    }, 1000);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add health check endpoint for Docker
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

// These would be added to the server.js file