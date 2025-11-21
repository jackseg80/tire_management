# TeslaMate Tire Management System

A comprehensive tire tracking and performance analytics system for TeslaMate with automatic statistics calculation and Grafana visualization.

**[Version française ci-dessous](#système-de-gestion-des-pneus-pour-teslamate)**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![TeslaMate](https://img.shields.io/badge/TeslaMate-Compatible-blue.svg)](https://github.com/teslamate-org/teslamate)

---

## Features

- **Track Unlimited Tire Sets** - Monitor summer, winter, and all-season tires
- **Automatic Statistics** - Calculates performance from TeslaMate drive data
- **Energy Consumption** - Track Wh/km with calibrated conversion factor
- **Driving Efficiency** - Monitor efficiency percentage per tire set
- **Temperature Correlation** - See how temperature affects performance
- **Historical Comparison** - Compare tire sets over time
- **Grafana Dashboard** - Visual analytics with 7+ panels
- **Easy Tire Changes** - Simple SQL commands to switch tires

## Screenshots

![Tire Management Dashboard](screenshots/dashboard.png)

*Dashboard showing tire performance statistics, consumption, and efficiency*

## Why This System?

Unlike generic tire tracking, this system:
- ✅ **Automatically calculates** statistics from your actual driving data
- ✅ **Uses calibrated factor (162)** for accurate Model S 75D consumption
- ✅ **Filters short trips** that skew consumption averages
- ✅ **Preserves historical data** when importing from TeslaFi
- ✅ **Updates seamlessly** with your TeslaMate installation

## Quick Start

### Prerequisites

- TeslaMate installed and running
- PostgreSQL database access
- Grafana (included with TeslaMate)
- Docker (recommended)

### Installation (5 minutes)

1. **Install the database schema:**

```bash
# Find your PostgreSQL container
docker ps | grep postgres

# Install schema (replace container name if needed)
docker exec -i teslamate-database-1 psql -U teslamate teslamate < tire_management.sql
```

2. **Add your tire data:**

```bash
docker exec -it teslamate-database-1 psql -U teslamate teslamate
```

Then paste:

```sql
-- Add a tire model
INSERT INTO tire_models (brand, model, size, type) VALUES
('Michelin', 'PilotSport 4', '245/45 R19 102V XL', 'Summer');

-- Add your current tire set
INSERT INTO tire_sets (car_id, name, tire_model_id, date_start) VALUES
(1, 'Summer 2024', 1, '2024-03-20');

-- Calculate statistics
SELECT update_current_tire_stats();

-- Exit
\q
```

3. **Import Grafana dashboard:**

- Open Grafana: `http://localhost:3000`
- Go to **Dashboards** → **Import**
- Upload `tire_dashboard.json`
- Select **TeslaMate** data source
- Click **Import**

Done!

## Dashboard Overview

The Grafana dashboard includes:

1. **Overview Table** - All tire sets with key statistics
2. **Distance Chart** - Total kilometers per tire set
3. **Consumption Chart** - Average Wh/km per tire set
4. **Current Tire Gauges** - Real-time stats for active tires
5. **Summer vs Winter** - Performance comparison pie chart
6. **Temperature Correlation** - See how weather affects consumption
7. **Efficiency Tracking** - Monitor driving efficiency over time

## 🔧 Usage

### Adding a New Tire Set

When changing tires:

```sql
-- 1. Close the current tire set
UPDATE tire_sets 
SET date_end = CURRENT_DATE
WHERE date_end IS NULL;

-- 2. Add the new tire set
INSERT INTO tire_sets (car_id, name, tire_model_id, date_start)
VALUES (1, 'Winter 2025-2026', 2, CURRENT_DATE);

-- 3. Update statistics
SELECT update_current_tire_stats();
```

Or use the automated script:

```bash
./update_current_tire.sh
```

### Updating Statistics

Statistics update automatically when you run:

```bash
./update_current_tire.sh
```

Or set up a cron job for automatic daily updates:

```bash
# Edit crontab
crontab -e

# Add this line (updates daily at 2 AM)
0 2 * * * cd /path/to/teslamate && ./update_current_tire.sh >> tire_update.log 2>&1
```

### Viewing Statistics

```sql
-- All tire sets
SELECT * FROM tire_sets_with_stats ORDER BY date_start DESC;

-- Current tire only
SELECT * FROM tire_sets_with_stats WHERE date_end IS NULL;

-- Summer vs Winter comparison
SELECT 
    type,
    AVG(consumption_wh_km) as avg_consumption,
    AVG(efficiency_percent) as avg_efficiency
FROM tire_sets_with_stats
GROUP BY type;
```

## 📐 Database Schema

### Tables

#### `tire_models`
Tire specifications catalog

| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL | Primary key |
| brand | VARCHAR(50) | Tire brand (e.g., Michelin) |
| model | VARCHAR(100) | Tire model (e.g., PilotSport 4) |
| size | VARCHAR(30) | Tire size (e.g., 245/45 R19) |
| type | VARCHAR(10) | Summer, Winter, All-Season |

#### `tire_sets`
Tire installation periods

| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL | Primary key |
| car_id | INTEGER | Reference to cars table |
| name | VARCHAR(50) | Set name (e.g., "Summer 2024") |
| tire_model_id | INTEGER | Reference to tire_models |
| date_start | DATE | Installation date |
| date_end | DATE | Removal date (NULL = active) |

#### `tire_set_statistics`
Calculated performance metrics (auto-populated)

| Column | Type | Description |
|--------|------|-------------|
| tire_set_id | INTEGER | Reference to tire_sets |
| kilometers | DECIMAL | Total distance driven |
| consumption_wh_km | DECIMAL | Average Wh/km |
| efficiency_percent | DECIMAL | Driving efficiency % |
| temperature_avg | DECIMAL | Average temperature |

#### `tire_sets_with_stats` (View)
Complete tire information with statistics - use this for queries!

### Function

#### `update_current_tire_stats()`

Recalculates statistics for active tire sets.

**Features:**
- Uses calibrated factor **162** for Model S 75D
- Filters trips < 5 km to avoid outliers
- Calculates true weighted average (not simple AVG)
- Computes efficiency: `(distance / rated_range_used) × 100`
- Only updates active tire sets (date_end = NULL)

**Usage:**
```sql
SELECT update_current_tire_stats();
```

## ⚙️ Technical Details

### Conversion Factor: 162 (Why not 187.5?)

The factor **162** is calibrated for Tesla Model S 75D using TeslaMate's `ideal_range_km` values.

**Why 162?**
- Theoretical: 75 kWh ÷ 400 km = 187.5 Wh/km
- But TeslaMate uses EPA range estimates, not actual battery capacity
- Calibrated against real TeslaFi data:
  - TeslaFi Summer 2024: **152 Wh/km** (reliable reference)
  - TeslaMate with 187.5: **176 Wh/km** (+15% too high)
  - TeslaMate with 162: **152 Wh/km** (perfect match!)

**Formula:** `187.5 × (152/176) = 162`

### Distance Filter: >= 5 km

Short trips are excluded from consumption calculations because:
- Battery preheating: 400-1000 Wh/km on 1-2 km trips
- HVAC disproportionately high on short trips
- These outliers significantly skew averages

**Example:**
- 1.0 km trip: 738 Wh/km (preheating)
- 2.1 km trip: 1160 Wh/km (climate control)
- 5.6 km trip: 426 Wh/km (still cold)
- 10+ km trips: 140-200 Wh/km (normal)

### Efficiency Calculation

Based on Grafana's "Efficiency" dashboard formula:

```
efficiency = (distance_driven / rated_range_used) × 100
```

**Interpretation:**
- 100% = Perfect efficiency (1 km driven = 1 km range used)
- 85% = Good (typical summer)
- 65% = Normal winter
- <60% = Poor conditions (very cold, heavy traffic)

## 🔍 Troubleshooting

### Statistics not updating

**Problem:** `update_current_tire_stats()` runs but values are 0 or NULL

**Solutions:**

```sql
-- 1. Check if drives exist for tire period
SELECT COUNT(*), MIN(start_date), MAX(start_date)
FROM drives 
WHERE car_id = 1 
  AND start_date >= '2024-01-01';

-- 2. Verify tire dates
SELECT name, date_start, date_end 
FROM tire_sets 
ORDER BY date_start DESC;

-- 3. Check for date overlap
-- Make sure tire dates overlap with drive dates

-- 4. Manually trigger update
SELECT update_current_tire_stats();
```

### Dashboard shows "No Data"

**Solutions:**

1. **Check time range** - Click time picker (top right), try "Last 2 years"
2. **Verify data source** - Dashboard settings → ensure "TeslaMate" is selected
3. **Run statistics** - `SELECT update_current_tire_stats();`
4. **Check query** - Edit panel → verify SQL queries are correct

### Container name issues

```bash
# Find your actual container name
docker ps | grep postgres

# Common names:
# - teslamate-database-1
# - teslamate_database_1
# - teslamate-postgres-1

# Use correct name in commands
docker exec -it YOUR_CONTAINER_NAME psql -U teslamate teslamate
```

### Wrong consumption values

If your consumption seems off:

1. **Check conversion factor** - Factor 162 is calibrated for Model S 75D
2. **Verify distance filter** - Should be >= 5 km
3. **Compare with known good data** - Use TeslaFi or other source as reference
4. **Check for outliers** - Look for extremely high consumption trips

```sql
-- Find potential outlier trips
SELECT 
    start_date,
    distance,
    (start_ideal_range_km - end_ideal_range_km) * 162 / distance as consumption
FROM drives
WHERE distance > 1
  AND distance < 10
ORDER BY consumption DESC
LIMIT 10;
```

## Advanced Usage

### Import Historical TeslaFi Data

If you have historical data with known statistics:

```sql
-- Method 1: Let function calculate from TeslaMate
INSERT INTO tire_sets (car_id, name, tire_model_id, date_start, date_end)
VALUES (1, 'Summer 2022', 1, '2022-06-01', '2022-11-15');
SELECT update_current_tire_stats();

-- Method 2: Manually set statistics (preserve TeslaFi data)
INSERT INTO tire_set_statistics (tire_set_id, kilometers, consumption_wh_km, efficiency_percent)
VALUES (1, 6221, 167, 75.9)
ON CONFLICT (tire_set_id) DO UPDATE 
SET kilometers = EXCLUDED.kilometers,
    consumption_wh_km = EXCLUDED.consumption_wh_km,
    efficiency_percent = EXCLUDED.efficiency_percent;
```

### Backup and Restore

```bash
# Full backup
docker exec teslamate-database-1 pg_dump -U teslamate teslamate | gzip > teslamate_backup_$(date +%Y%m%d).sql.gz

# Tire data only backup
docker exec teslamate-database-1 pg_dump -U teslamate -d teslamate -t tire_models -t tire_sets -t tire_set_statistics > tire_backup.sql

# Restore
gunzip -c teslamate_backup_20241120.sql.gz | docker exec -i teslamate-database-1 psql -U teslamate teslamate
```

### Custom Queries

```sql
-- Monthly consumption trend
SELECT 
    DATE_TRUNC('month', d.start_date) as month,
    AVG((d.start_ideal_range_km - d.end_ideal_range_km) * 162 / d.distance) as avg_consumption
FROM drives d
JOIN tire_sets ts ON d.start_date >= ts.date_start 
    AND (ts.date_end IS NULL OR d.start_date <= ts.date_end)
WHERE d.distance >= 5
GROUP BY 1
ORDER BY 1 DESC;

-- Tire wear analysis
SELECT 
    name,
    date_end - date_start as days_used,
    kilometers,
    ROUND(kilometers / (date_end - date_start + 1), 2) as km_per_day
FROM tire_sets_with_stats
WHERE date_end IS NOT NULL
ORDER BY km_per_day DESC;
```

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

MIT License - See [LICENSE](LICENSE) file for details

## Acknowledgments

- [TeslaMate](https://github.com/teslamate-org/teslamate) - The amazing Tesla data logger
- TeslaMate community for feature requests and feedback
- Contributors who helped test and improve the system

## Support

- **Bug Reports:** [Open an issue](https://github.com/jackseg80/teslamate-tire-management/issues)
- **Feature Requests:** [Open an issue](https://github.com/jackseg80/teslamate-tire-management/issues)
- **Questions:** [Discussions](https://github.com/jackseg80/teslamate-tire-management/discussions)

---

# Système de Gestion des Pneus pour TeslaMate

Un système complet de suivi et d'analyse des performances des pneus pour TeslaMate avec calcul automatique des statistiques et visualisation Grafana.

## Fonctionnalités

- **Suivi Illimité de Pneus** - Gérez vos pneus été, hiver et toutes saisons
- **Statistiques Automatiques** - Calcul depuis vos données de conduite TeslaMate
- **Consommation d'Énergie** - Suivi en Wh/km avec facteur de conversion calibré
- **Efficacité de Conduite** - Surveillance du pourcentage d'efficacité par jeu
- **Corrélation Température** - Impact de la température sur les performances
- **Comparaison Historique** - Comparez les jeux de pneus dans le temps
- **Dashboard Grafana** - Analytics visuels avec plus de 7 panels
- **Changements Faciles** - Commandes SQL simples pour changer de pneus

## Démarrage Rapide

### Prérequis

- TeslaMate installé et fonctionnel
- Accès à la base PostgreSQL
- Grafana (inclus avec TeslaMate)
- Docker (recommandé)

### Installation (5 minutes)

1. **Installer le schéma de base de données :**

```bash
# Trouver votre conteneur PostgreSQL
docker ps | grep postgres

# Installer le schéma (remplacer le nom si nécessaire)
docker exec -i teslamate-database-1 psql -U teslamate teslamate < tire_management.sql
```

2. **Ajouter vos données de pneus :**

```bash
docker exec -it teslamate-database-1 psql -U teslamate teslamate
```

Puis coller :

```sql
-- Ajouter un modèle de pneu
INSERT INTO tire_models (brand, model, size, type) VALUES
('Michelin', 'PilotSport 4', '245/45 R19 102V XL', 'Summer');

-- Ajouter votre jeu actuel
INSERT INTO tire_sets (car_id, name, tire_model_id, date_start) VALUES
(1, 'Été 2024', 1, '2024-03-20');

-- Calculer les statistiques
SELECT update_current_tire_stats();

-- Quitter
\q
```

3. **Importer le dashboard Grafana :**

- Ouvrir Grafana : `http://localhost:3000`
- Aller dans **Dashboards** → **Import**
- Télécharger `tire_dashboard.json`
- Sélectionner la source **TeslaMate**
- Cliquer sur **Import**

Terminé !

## 🔧 Utilisation

### Ajouter un Nouveau Jeu de Pneus

Lors d'un changement de pneus :

```sql
-- 1. Fermer le jeu actuel
UPDATE tire_sets 
SET date_end = CURRENT_DATE
WHERE date_end IS NULL;

-- 2. Ajouter le nouveau jeu
INSERT INTO tire_sets (car_id, name, tire_model_id, date_start)
VALUES (1, 'Hiver 2025-2026', 2, CURRENT_DATE);

-- 3. Mettre à jour les statistiques
SELECT update_current_tire_stats();
```

Ou utiliser le script automatisé :

```bash
./update_current_tire.sh
```

### Mise à Jour des Statistiques

Les statistiques se mettent à jour automatiquement :

```bash
./update_current_tire.sh
```

Ou configurez un cron pour une mise à jour quotidienne automatique :

```bash
# Éditer crontab
crontab -e

# Ajouter cette ligne (mise à jour tous les jours à 2h)
0 2 * * * cd /chemin/vers/teslamate && ./update_current_tire.sh >> tire_update.log 2>&1
```

## Schéma de Base de Données

### Tables Principales

- **`tire_models`** - Catalogue des spécifications de pneus
- **`tire_sets`** - Périodes d'installation des pneus
- **`tire_set_statistics`** - Métriques de performance (auto-calculées)
- **`tire_sets_with_stats`** - Vue complète (à utiliser pour les requêtes)

### Fonction

**`update_current_tire_stats()`** - Recalcule les statistiques pour les jeux actifs

## Détails Techniques

### Facteur de Conversion : 162

Le facteur **162** est calibré pour Tesla Model S 75D.

**Pourquoi 162 et pas 187.5 ?**
- Théorique : 75 kWh ÷ 400 km = 187.5 Wh/km
- TeslaMate utilise les estimations EPA, pas la capacité réelle
- Calibré sur données TeslaFi réelles :
  - TeslaFi Été 2024 : **152 Wh/km** (référence fiable)
  - TeslaMate avec 187.5 : **176 Wh/km** (+15% trop élevé)
  - TeslaMate avec 162 : **152 Wh/km** (parfait !)

### Filtre Distance : >= 5 km

Les trajets courts sont exclus car :
- Préchauffage batterie : 400-1000 Wh/km sur 1-2 km
- Climatisation disproportionnée sur trajets courts
- Ces valeurs extrêmes faussent les moyennes

## Dépannage

### Statistiques non mises à jour

```sql
-- Vérifier les trajets dans la période
SELECT COUNT(*), MIN(start_date), MAX(start_date)
FROM drives WHERE car_id = 1 AND start_date >= '2024-01-01';

-- Vérifier les dates des pneus
SELECT name, date_start, date_end FROM tire_sets ORDER BY date_start DESC;

-- Relancer la mise à jour
SELECT update_current_tire_stats();
```

### Dashboard affiche "No Data"

1. Vérifier la plage temporelle (en haut à droite)
2. Vérifier la source de données
3. Exécuter `SELECT update_current_tire_stats();`

## Licence

Licence MIT - Voir le fichier [LICENSE](LICENSE)

## Remerciements

- [TeslaMate](https://github.com/teslamate-org/teslamate) - L'excellent enregistreur de données Tesla
- La communauté TeslaMate pour les demandes et retours

---

**Made with ❤️ for the TeslaMate community**