# 🛒 Retail Sales Forecasting + Inventory Intelligence

[![Streamlit App](https://static.streamlit.io/badges/streamlit_badge_black_white.svg)](https://retail-forecasting-kknzt4ksfewdmhvzy6nko8.streamlit.app/)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-4169E1?logo=postgresql&logoColor=white)
![Python](https://img.shields.io/badge/Python-3.10-3776AB?logo=python&logoColor=white)
![Streamlit](https://img.shields.io/badge/Streamlit-Deployed-FF4B4B?logo=streamlit&logoColor=white)
![SQL Scripts](https://img.shields.io/badge/SQL_Scripts-60-orange)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)
![License](https://img.shields.io/badge/License-MIT-yellow)

> **End-to-end retail analytics project built entirely in PostgreSQL.**
> Sales forecasting, inventory intelligence, and an interactive dashboard
> for 1,115 German Rossmann stores across Jan 2013 – Jul 2015.

### 🔗 [Live Dashboard](https://retail-forecasting-kknzt4ksfewdmhvzy6nko8.streamlit.app/) &nbsp;|&nbsp; 📊 [Kaggle Dataset](https://www.kaggle.com/c/rossmann-store-sales)

---

## 📌 Project Highlights

| Metric | Value |
|--------|-------|
| Stores covered | 1,115 |
| Total revenue analysed | €5.78 Billion |
| Training rows | 844,338 |
| Forecast MAPE (ensemble) | **17.40%** |
| Forecast RMSE (ensemble) | **1,554** |
| Excellent forecasts (<10% error) | **37.8%** |
| SQL scripts written | **60** |
| PostgreSQL views created | **27** |
| Days to build | **15** |

---

## 🖥️ Live Dashboard

The dashboard has 6 pages — all data served from
pre-computed PostgreSQL tables:

| Page | What you'll see |
|------|----------------|
| 🏠 Home | KPI cards, monthly revenue chart, model scorecard |
| 📈 Sales Trends | Seasonality index, day-of-week patterns, promo impact |
| 🔮 Forecast | Store-level forecast with 95% confidence intervals |
| 🏪 Store Analysis | Accuracy vs volume scatter, segment performance |
| 📦 Inventory | Reorder alerts, safety stock, risk distribution |
| 🎯 Model Performance | RMSE comparison, monthly MAPE, quality distribution |

---

## 🏗️ Architecture

```
Kaggle CSVs (train.csv · test.csv · store.csv)
            │
            ▼
    PostgreSQL 17 (pgAdmin)
    ┌─────────────────────────────┐
    │  raw_train · raw_store      │  ← Ingestion layer
    │  raw_test                   │
    └────────────┬────────────────┘
                 │
                 ▼
    ┌─────────────────────────────┐
    │  sales (844K rows)          │  ← Clean production table
    │  40+ features extracted     │
    └────────────┬────────────────┘
                 │
        ┌────────┴────────┐
        ▼                 ▼
   EDA Layer         Feature Engineering
   (10 scripts)      (5 scripts, 40+ features)
        │                 │
        └────────┬────────┘
                 ▼
    ┌─────────────────────────────┐
    │  Forecasting Models         │
    │  · DOW_AVG   MAPE 17.69%   │
    │  · Trend+Seasonal 18.50%   │
    │  · Ensemble  MAPE 17.40%   │
    └────────────┬────────────────┘
                 │
                 ▼
    ┌─────────────────────────────┐
    │  Inventory Intelligence     │
    │  · Safety stock (95% SL)   │
    │  · Reorder alerts           │
    │  · Store segmentation       │
    └────────────┬────────────────┘
                 │
                 ▼
    ┌─────────────────────────────┐
    │  Materialised Tables        │
    │  t_final_forecast (828K)   │
    │  t_store_summary (1,115)   │
    │  t_monthly_forecast (34K)  │
    │  t_kpi_summary (1 row)     │
    └────────────┬────────────────┘
                 │
                 ▼
    Streamlit Dashboard (Python display only)
```

---

## 📂 Project Structure

```
retail-forecasting/
├── README.md
├── sql/                           # 60 SQL scripts
│   ├── 01_create_tables.sql       # Raw schema design
│   ├── 02_load_data.sql           # pgAdmin CSV import
│   ├── 03_create_clean_table.sql  # Cleaning + feature extraction
│   ├── 04_sanity_checks.sql       # Data validation
│   ├── 05_eda_sales_trends.sql    # YoY growth, monthly trends
│   ├── 06_eda_day_of_week.sql     # Day-of-week patterns
│   ├── 07_eda_holiday_promo.sql   # Holiday + promo effects
│   ├── 08_eda_store_analysis.sql  # Store type + competition
│   ├── 09_eda_seasonality.sql     # Rolling averages
│   ├── 10_eda_distribution.sql    # IQR outlier detection
│   ├── 11–18_ts_*.sql             # Time series decomposition
│   ├── 19–24_adv_*.sql            # Advanced SQL analytics
│   ├── 25–29_feat_*.sql           # Feature engineering
│   ├── 30–34_inv_*.sql            # Inventory intelligence
│   ├── 35–45_forecast_*.sql       # Forecasting models
│   ├── 46–51_eval_*.sql           # Model evaluation + ensemble
│   └── 52–60_mat_*.sql            # Materialised tables
├── dashboard/
│   ├── app.py                     # Local dashboard (PostgreSQL)
│   ├── app_cloud.py               # Cloud dashboard (CSV)
│   ├── requirements.txt
│   └── data/                      # Pre-computed CSV exports
│       ├── kpi_summary.csv
│       ├── store_summary.csv
│       ├── monthly_forecast.csv
│       ├── model_scorecard.csv
│       ├── promo_effectiveness.csv
│       ├── store_performance.csv
│       ├── forecast_sample.csv
│       └── alerts.csv
└── data/
    ├── raw/                       # Kaggle CSVs (gitignored)
    └── processed/                 # Cleaned data
```

---

## 🔍 Key Findings from the Data

### Sales Patterns
- **Monday** is the peak trading day — avg sales 8,337 vs Sunday's 2,912 (**65% gap**)
- **December** has a seasonality index of **+1,454** above trend — Christmas dominates
- **Store type B** (only 17 stores) achieves **10,233 avg daily sales** — 48% above type A
- **2015 data** only covers Jan–Jul — accounted for in all YoY comparisons

### Promo Intelligence
- Promotions lift sales by **38.8%** overall (8,229 vs 5,930 avg)
- **Early promo adopters** (Q1 2013) outperform late adopters by **2x** in type B stores
- Promo days account for **44.6%** of all trading days — uniformly distributed

### Competition Paradox
- Stores within **500m of a competitor** have the **highest avg sales (7,615)**
- This is explained by high-footfall city centre locations — not competition effect

### Forecasting
- **Lag-14 correlation (r=0.74)** beats lag-7 (r=0.55) — same weekday 2 weeks ago is the best predictor
- **DOW_AVG beats MA_7** on MAPE — weekly seasonality dominates trend in retail
- **Ensemble mean bias: -23** — opposite model biases cancel almost perfectly

### Inventory
- **18 stores** flagged WARNING — need reorder within 24 hours
- **55 stores** flagged WATCH — demand surging at 1.34x normal
- **Premium + Low risk stores** have lowest MAPE (15.6%) — largest stores are most predictable

---

## 🛠️ Tech Stack

| Tool | Role |
|------|------|
| **PostgreSQL 17** | All analytics, EDA, feature engineering, forecasting |
| **pgAdmin 4** | Query execution, CSV import/export |
| **Python 3.10** | Streamlit display layer only — zero modelling |
| **Streamlit** | Interactive 6-page dashboard |
| **Plotly** | Charts and visualisations |
| **SQLAlchemy** | PostgreSQL ↔ Python connector |

---

## 📊 SQL Techniques Used

```sql
-- Linear regression for trend forecasting
REGR_SLOPE(actual_sales, day_num)
REGR_INTERCEPT(actual_sales, day_num)

-- Autocorrelation analysis
CORR(total_sales, lag_7)

-- Median imputation
PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY col)

-- Rolling averages
AVG(sales) OVER (
    PARTITION BY "Store" ORDER BY "Date"
    ROWS BETWEEN 27 PRECEDING AND 1 PRECEDING
)

-- Conditional aggregation
AVG("Sales") FILTER (WHERE "Promo" = 1)

-- Store rankings
DENSE_RANK() OVER (ORDER BY avg_daily_sales DESC)
PERCENT_RANK() OVER (ORDER BY avg_daily_sales)
NTILE(4) OVER (ORDER BY cv_pct)

-- Cyclical feature encoding (in SQL)
ROUND(SIN(2 * PI() * month / 12.0)::NUMERIC, 4)
ROUND(COS(2 * PI() * month / 12.0)::NUMERIC, 4)
```

---

## 🚀 Run Locally

### Prerequisites
- PostgreSQL 17 installed
- pgAdmin 4
- Python 3.10 + Anaconda
- Rossmann dataset from Kaggle

### Setup

```bash
# 1. Clone the repo
git clone https://github.com/smukherjee1116-lgtm/retail-forecasting.git
cd retail-forecasting

# 2. Create environment
conda create -n retail-forecast python=3.10 -y
conda activate retail-forecast
pip install -r dashboard/requirements.txt

# 3. Create PostgreSQL database named 'Retail_forecast'
# 4. Download train.csv, test.csv, store.csv from Kaggle
#    Place in data/raw/

# 5. Run SQL scripts in pgAdmin in order (01 → 60)
#    Use pgAdmin Import/Export for 02_load_data.sql

# 6. Run dashboard
streamlit run dashboard/app.py
```

---

## 📈 Model Results

### Test Set Performance (Jan–Jul 2015)

| Model | RMSE | MAE | MAPE | Bias | 95% Coverage |
|-------|------|-----|------|------|-------------|
| DOW_AVG (baseline) | 1,633 | 1,211 | 17.69% | +182 | 95.4% |
| Trend + Seasonal | 1,598 | 1,195 | 18.50% | -214 | 94.9% |
| **Ensemble (weighted)** | **1,554** | **1,156** | **17.40%** | **-23** | **95.6%** |

### Forecast Quality Distribution (Test Set)

| Quality Band | Pct of Forecasts |
|-------------|-----------------|
| Excellent (<10% error) | 37.8% |
| Good (10–20% error) | 29.7% |
| Fair (20–30% error) | 16.6% |
| Poor (>30% error) | 15.9% |

---

## 🏪 Store Segmentation

| Segment | Stores | Avg Daily Forecast | Avg MAPE |
|---------|--------|-------------------|---------|
| Premium (>€10K) | 95 | €12,439 | 15.9% |
| High (€7K–€10K) | 380 | €8,108 | 17.7% |
| Medium (€5K–€7K) | 431 | €5,991 | 18.2% |
| Standard (<€5K) | 207 | €4,304 | 18.3% |

---

## 👤 Author

**Soham Mukherjee**
Data Scientist · 3+ Years Experience · Kolkata, India

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0A66C2?logo=linkedin&logoColor=white)]www.linkedin.com/in/soham-mukherjee-kolkata
[![GitHub](https://img.shields.io/badge/GitHub-Follow-181717?logo=github&logoColor=white)](https://github.com/smukherjee1116-lgtm)
[![Dashboard](https://img.shields.io/badge/Live_Dashboard-View-FF4B4B?logo=streamlit&logoColor=white)](https://retail-forecasting-kknzt4ksfewdmhvzy6nko8.streamlit.app/)

---

## 🗂️ Other Portfolio Projects

| Project | Description | Stack |
|---------|-------------|-------|
| [Amazon Beauty Recommender](https://github.com/smukherjee1116-lgtm) | SVD + TF-IDF + Hybrid recommendation system | Python · Streamlit |
| [Customer Segmentation + CLV](https://github.com/smukherjee1116-lgtm) | RFM + PostgreSQL + CLV analysis | PostgreSQL · Python · Streamlit |
| **Retail Forecasting** | This project | PostgreSQL · Streamlit |

---

## 📄 License

MIT License — free to use as reference with attribution.
```

---