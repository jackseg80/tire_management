# TeslaMate Tire Management System

A comprehensive tire tracking and analytics system for TeslaMate that monitors tire performance, consumption, and TPMS data.

[Version française ci-dessous](#système-de-gestion-des-pneus-pour-teslamate)

---

## Features

- 📊 Track multiple tire sets (summer/winter)
- 📈 Real-time tire performance statistics
- 🌡️ Temperature and pressure monitoring (TPMS)
- ⚡ Energy consumption per tire set (Wh/km)
- 🔄 Automatic calculation from TeslaMate drive data
- 📉 Historical tire performance comparison
- 🎯 Grafana dashboard for visualization

## Screenshots

![Tire Management Dashboard](screenshots/dashboard.png)

## Requirements

- TeslaMate (any recent version)
- PostgreSQL database access
- Grafana
- Docker (recommended)

## Installation

### 1. Database Setup

Connect to your TeslaMate PostgreSQL database:

```bash
docker exec -it teslamate_database_1 psql -U teslamate teslamate
```

Or if your container has a different name:

```bash
docker ps | grep postgres
docker exec -it <container_name> psql -U teslamate teslamate
```

### 2. Create Database Schema

Run the SQL script to create the necessary tables and functions:

```bash
docker exec -i teslamate_database_1 psql -U teslamate teslamate < tire_management.sql
```

Or copy and paste the content of `tire_management.sql` directly into your psql session.

### 3. Import Your Tire Data

Edit the SQL script to add your tire sets. Example:

```sql
INSERT INTO tire_sets (name, brand, model, size, start_date, end_date, tire_type, initial_odometer, final_odometer) VALUES
('Summer 2024', 'Michelin', 'PilotSport 3', '245/45 R19 102V XL', '2024-03-15', '2024-11-01', 'summer', 145000, 155000),
('Winter 2024-2025', 'Goodyear', 'UltraGrip Performance+', '245/45 R19 102V XL', '2024-11-01', NULL, 'winter', 155000, NULL);
```

**Important fields:**
- `start_date` and `end_date`: Define the period this tire set was active
- `initial_odometer` and `final_odometer`: Odometer readings at installation/removal
- Set `end_date` and `final_odometer` to `NULL` for currently active tires

### 4. Calculate Statistics

After importing tire data, run the calculation function:

```sql
SELECT update_tire_statistics();
```

This function will:
- Calculate total distance for each tire set
- Compute average energy consumption (Wh/km)
- Calculate efficiency percentages
- Aggregate temperature data

### 5. Import Grafana Dashboard

1. Open Grafana (usually at http://localhost:3000)
2. Go to Dashboards → Import
3. Upload `tire_dashboard.json`
4. Select your TeslaMate data source
5. Click Import

## Usage

### Adding a New Tire Set

```sql
-- End the current tire set
UPDATE tire_sets 
SET end_date = '2025-11-16', 
    final_odometer = 165000
WHERE name = 'Winter 2024-2025';

-- Add the new tire set
INSERT INTO tire_sets (name, brand, model, size, start_date, tire_type, initial_odometer)
VALUES ('Summer 2025', 'Michelin', 'PilotSport 4', '245/45 R19 102V XL', '2025-03-20', 'summer', 165000);

-- Recalculate statistics
SELECT update_tire_statistics();
```

### Manual Data Refresh

The statistics are calculated from TeslaMate's drive data. To refresh:

```sql
SELECT update_tire_statistics();
```

You can also set up a PostgreSQL cron job or trigger to automate this.

### Viewing Statistics

```sql
SELECT * FROM tire_set_statistics ORDER BY start_date DESC;
```

## Database Schema

### Tables

#### `tire_sets`
Stores information about each set of tires installed on the vehicle.

| Column | Type | Description |
|--------|------|-------------|
| id | SERIAL | Primary key |
| name | VARCHAR(100) | Tire set name (e.g., "Summer 2024") |
| brand | VARCHAR(100) | Tire brand |
| model | VARCHAR(100) | Tire model |
| size | VARCHAR(50) | Tire size specification |
| start_date | DATE | Installation date |
| end_date | DATE | Removal date (NULL if currently active) |
| tire_type | VARCHAR(20) | 'summer' or 'winter' |
| initial_odometer | INTEGER | Odometer at installation |
| final_odometer | INTEGER | Odometer at removal (NULL if active) |
| notes | TEXT | Additional notes |

#### `tire_set_statistics`
Calculated statistics for each tire set (automatically populated).

| Column | Type | Description |
|--------|------|-------------|
| tire_set_id | INTEGER | Reference to tire_sets |
| total_km | DECIMAL | Total distance driven |
| total_kwh | DECIMAL | Total energy consumed |
| avg_consumption_whkm | DECIMAL | Average Wh/km |
| avg_efficiency | DECIMAL | Average efficiency % |
| avg_temp | DECIMAL | Average temperature |
| total_drives | INTEGER | Number of drives |

### Function

#### `update_tire_statistics()`
Recalculates all tire statistics from TeslaMate drive data. Should be run after:
- Adding new tire sets
- Updating tire set dates
- Periodically to refresh current tire data

## Troubleshooting

### Statistics not updating
```sql
-- Check if drives exist in the date range
SELECT COUNT(*), MIN(start_date), MAX(start_date) 
FROM drives 
WHERE start_date BETWEEN '2024-01-01' AND '2024-12-31';

-- Verify tire set dates
SELECT id, name, start_date, end_date FROM tire_sets;

-- Manually run update
SELECT update_tire_statistics();
```

### Dashboard shows no data
- Verify the data source is correctly configured
- Check the time range in Grafana
- Ensure tire_set_statistics table has data
- Refresh the dashboard

### Container name issues
```bash
# Find your container names
docker ps | grep teslamate
docker ps | grep postgres

# Use the correct container name in commands
docker exec -it <your_container_name> psql -U teslamate teslamate
```

## Contributing

Feel free to submit issues and pull requests!

## License

MIT License - See LICENSE file for details

---

## Système de Gestion des Pneus pour TeslaMate

Un système complet de suivi et d'analyse des pneus pour TeslaMate qui surveille les performances, la consommation et les données TPMS.

## Fonctionnalités

- 📊 Suivi de plusieurs jeux de pneus (été/hiver)
- 📈 Statistiques de performance en temps réel
- 🌡️ Surveillance de la température et de la pression (TPMS)
- ⚡ Consommation d'énergie par jeu de pneus (Wh/km)
- 🔄 Calcul automatique à partir des données de conduite TeslaMate
- 📉 Comparaison historique des performances
- 🎯 Dashboard Grafana pour la visualisation

## Prérequis

- TeslaMate (version récente)
- Accès à la base de données PostgreSQL
- Grafana
- Docker (recommandé)

## Installation

### 1. Configuration de la Base de Données

Connectez-vous à votre base PostgreSQL TeslaMate :

```bash
docker exec -it teslamate_database_1 psql -U teslamate teslamate
```

Ou si votre conteneur a un nom différent :

```bash
docker ps | grep postgres
docker exec -it <nom_conteneur> psql -U teslamate teslamate
```

### 2. Créer le Schéma de Base de Données

Exécutez le script SQL pour créer les tables et fonctions nécessaires :

```bash
docker exec -i teslamate_database_1 psql -U teslamate teslamate < tire_management.sql
```

Ou copiez-collez le contenu de `tire_management.sql` directement dans votre session psql.

### 3. Importer Vos Données de Pneus

Modifiez le script SQL pour ajouter vos jeux de pneus. Exemple :

```sql
INSERT INTO tire_sets (name, brand, model, size, start_date, end_date, tire_type, initial_odometer, final_odometer) VALUES
('Été 2024', 'Michelin', 'PilotSport 3', '245/45 R19 102V XL', '2024-03-15', '2024-11-01', 'summer', 145000, 155000),
('Hiver 2024-2025', 'Goodyear', 'UltraGrip Performance+', '245/45 R19 102V XL', '2024-11-01', NULL, 'winter', 155000, NULL);
```

**Champs importants :**
- `start_date` et `end_date` : Définissent la période d'utilisation du jeu de pneus
- `initial_odometer` et `final_odometer` : Relevés kilométriques à l'installation/retrait
- Mettre `end_date` et `final_odometer` à `NULL` pour les pneus actuellement en service

### 4. Calculer les Statistiques

Après l'import des données, lancez la fonction de calcul :

```sql
SELECT update_tire_statistics();
```

Cette fonction va :
- Calculer la distance totale pour chaque jeu de pneus
- Calculer la consommation moyenne d'énergie (Wh/km)
- Calculer les pourcentages d'efficacité
- Agréger les données de température

### 5. Importer le Dashboard Grafana

1. Ouvrez Grafana (généralement sur http://localhost:3000)
2. Allez dans Dashboards → Import
3. Téléchargez `tire_dashboard.json`
4. Sélectionnez votre source de données TeslaMate
5. Cliquez sur Import

## Utilisation

### Ajouter un Nouveau Jeu de Pneus

```sql
-- Terminer le jeu de pneus actuel
UPDATE tire_sets 
SET end_date = '2025-11-16', 
    final_odometer = 165000
WHERE name = 'Hiver 2024-2025';

-- Ajouter le nouveau jeu de pneus
INSERT INTO tire_sets (name, brand, model, size, start_date, tire_type, initial_odometer)
VALUES ('Été 2025', 'Michelin', 'PilotSport 4', '245/45 R19 102V XL', '2025-03-20', 'summer', 165000);

-- Recalculer les statistiques
SELECT update_tire_statistics();
```

### Rafraîchissement Manuel des Données

Les statistiques sont calculées à partir des données de conduite TeslaMate. Pour rafraîchir :

```sql
SELECT update_tire_statistics();
```

Vous pouvez également configurer un cron PostgreSQL ou un trigger pour automatiser cela.

## Contribution

N'hésitez pas à soumettre des issues et des pull requests !

## Licence

Licence MIT - Voir le fichier LICENSE pour les détails
