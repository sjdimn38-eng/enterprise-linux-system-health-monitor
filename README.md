# Enterprise Linux System Health Monitor (ELSHM)

A modular Bash-based Linux System Health Monitoring tool that collects, analyzes, and reports the health status of a Linux system through an interactive terminal dashboard and HTML reports.

---

## Features

- System Information
- CPU Monitoring
- Memory Monitoring
- Disk Monitoring
- Network Monitoring
- Process Monitoring
- Service Monitoring
- Security Monitoring
- Log Monitoring
- Overall Health Score
- HTML Report Generation
- Colorized Terminal Dashboard
- Logging Support
- Modular Architecture

---

## Technologies Used

- Bash Shell
- Linux (Kali Linux)
- awk
- sed
- grep
- systemctl
- journalctl
- ss
- HTML
- CSS

---

## Project Structure

```text
enterprise-linux-system-health-monitor/

├── bin/
├── config/
├── dashboard/
├── lib/
├── logs/
├── modules/
├── reports/
├── screenshots/
├── tests/
├── main.sh
├── report.sh
├── README.md
├── LICENSE
├── CHANGELOG.md
└── CONTRIBUTING.md
```

---

## Modules

- System Information
- CPU Monitoring
- Memory Monitoring
- Disk Monitoring
- Network Monitoring
- Process Monitoring
- Service Monitoring
- Security Monitoring
- Log Monitoring

---

## Installation

Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/enterprise-linux-system-health-monitor.git

cd enterprise-linux-system-health-monitor
```

Make scripts executable:

```bash
chmod +x main.sh
chmod +x modules/*.sh
chmod +x lib/*.sh
```

Run the application:

```bash
sudo ./main.sh
```

---

## Sample Output

The tool displays:

- System Dashboard
- Health Score
- CPU Usage
- Memory Usage
- Disk Usage
- Network Information
- Running Services
- Security Information
- Log Analysis

It also generates an HTML report inside the `reports/` directory.

---

## Future Improvements

- Email Alerts
- Real-Time Monitoring
- Prometheus Integration
- Grafana Dashboard
- Docker Monitoring
- Email Notifications

---

## Author

**Sajid Imran**

Linux System Administrator | Cybersecurity Enthusiast | Bash Scripting | IT Support

---

## License

This project is licensed under the MIT License.
