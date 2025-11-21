# Changelog

All notable changes to TeslaMate Tire Management will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-20

### Added
- Initial release of TeslaMate Tire Management System
- Database schema with `tire_models`, `tire_sets`, and `tire_set_statistics` tables
- `tire_sets_with_stats` view for easy querying
- `update_current_tire_stats()` function for automatic statistics calculation
- Calibrated conversion factor (162) for Tesla Model S 75D
- Distance filter (>= 5 km) to exclude short trip outliers
- Driving efficiency calculation based on rated range
- Temperature correlation tracking
- Grafana dashboard with 7+ panels:
  - Overview table with all tire sets
  - Distance and consumption charts
  - Current tire gauges
  - Summer vs Winter comparison
  - Temperature correlation
- Automated update script (`update_current_tire.sh`)
- Example data file with sample tire history
- Comprehensive documentation (README, QUICKSTART, INSTALLATION)
- MIT License

### Technical Details
- **Conversion Factor:** 162 Wh/km (calibrated against TeslaFi historical data)
- **Distance Filter:** >= 5 km (excludes outlier short trips)
- **Efficiency Formula:** `(distance / rated_range_used) × 100`
- **Weighted Average:** Uses `SUM() / SUM()` not `AVG()` for accurate consumption

### Documentation
- English and French bilingual README
- Quick Start guide (5-minute setup)
- Detailed installation instructions
- Troubleshooting guide
- Database schema documentation
- Example queries and use cases

## [Unreleased]

### Planned Features
- Automatic statistics refresh via PostgreSQL triggers
- TPMS (Tire Pressure Monitoring) integration
- Tire wear prediction
- Cost per kilometer tracking
- Rotation reminder alerts
- Mobile app integration via API
- Advanced analytics dashboard
- Multi-vehicle support enhancements

### Under Consideration
- Tire tread depth tracking
- Service history integration
- Weather API integration for better temperature correlation
- Export to CSV/PDF reports
- Email notifications for anomalies
- Integration with tire vendor APIs

## Version History

### v1.0.0 (2025-11-20) - Initial Release

The first public release includes all core functionality:
- Complete tire tracking system
- Automatic statistics from TeslaMate data
- Grafana visualization
- Calibrated for accurate consumption tracking
- Full documentation

---

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Reporting Issues

Found a bug or have a feature request? Please [open an issue](https://github.com/jackseg80/teslamate-tire-management/issues) on GitHub.

---

**Note:** Replace `jackseg80` with your actual GitHub username throughout this project.
