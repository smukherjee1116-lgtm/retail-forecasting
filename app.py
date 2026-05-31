import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
from sqlalchemy import create_engine, text
from dotenv import load_dotenv
import os

load_dotenv()

st.set_page_config(
    page_title="Retail Forecasting | Rossmann",
    page_icon="🛒",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ── Connection (all data comes from PostgreSQL) ───────────────────────────────
# ── Connection (all data comes from PostgreSQL) ───────────────────────────────
@st.cache_resource
def get_engine():
    from sqlalchemy import URL
    url = URL.create(
        drivername="postgresql+psycopg2",
        username="postgres",
        password="Purba1508@",
        host="127.0.0.1",
        port=5432,
        database="Retail_forecast"
    )
    return create_engine(url)

from sqlalchemy import create_engine, text
@st.cache_data(ttl=300)
def sql(query):
    with get_engine().connect() as conn:
        return pd.read_sql(text(query), conn)
# ── Load KPI row ──────────────────────────────────────────────────────────────
kpi = sql("SELECT * FROM t_kpi_summary").iloc[0]

# ── Sidebar ───────────────────────────────────────────────────────────────────
st.sidebar.title("🛒 Retail Forecasting")
st.sidebar.markdown("**Rossmann Stores · Germany**")
st.sidebar.markdown(f"📅 {kpi['data_period']}")
st.sidebar.divider()
page = st.sidebar.radio("Go to", [
    "🏠 Home",
    "📈 Sales Trends",
    "🔮 Forecast",
    "🏪 Store Analysis",
    "📦 Inventory",
    "🎯 Model Performance"
])
st.sidebar.divider()
st.sidebar.caption(
    "All analytics built in PostgreSQL.\n"
    "Python used as display layer only."
)

# ══════════════════════════════════════════════════════════════════════════════
# PAGE 1 — HOME
# ══════════════════════════════════════════════════════════════════════════════
if page == "🏠 Home":
    st.title("🛒 Retail Sales Forecasting + Inventory Intelligence")
    st.markdown(
        "**Rossmann Store Sales · 1,115 German Stores · "
        "Jan 2013 – Jul 2015 · Pure PostgreSQL Analytics**"
    )
    st.divider()

    # Row 1 — Dataset KPIs
    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Total Stores",      f"{int(kpi['total_stores']):,}")
    c2.metric("Total Revenue",     f"€{int(kpi['total_revenue'])/1e9:.2f}B")
    c3.metric("Avg Daily Sales",   f"€{int(kpi['avg_daily_sales']):,}")
    c4.metric("Max Single Day",    f"€{int(kpi['max_daily_sales']):,}")

    st.divider()

    # Row 2 — Model KPIs
    c5, c6, c7, c8 = st.columns(4)
    c5.metric("Ensemble RMSE",     f"{int(kpi['ensemble_rmse']):,}")
    c6.metric("Ensemble MAPE",     f"{float(kpi['ensemble_mape']):.2f}%")
    c7.metric("Excellent Forecasts",
              f"{float(kpi['pct_forecasts_excellent']):.1f}%",
              help="Forecasts within 10% of actual")
    c8.metric("Stores Need Reorder",
              f"{int(kpi['stores_needing_reorder'])}",
              delta=f"{int(kpi['stores_demand_surging'])} surging",
              delta_color="inverse")

    st.divider()

    # Monthly revenue chart
    st.subheader("📊 Monthly Revenue — Actual vs Ensemble Forecast")
    monthly = sql("""
        SELECT
            year, month, month_name, split,
            SUM(actual_monthly_sales)   AS actual,
            SUM(forecast_monthly_sales) AS forecast
        FROM t_monthly_forecast
        GROUP BY year, month, month_name, split
        ORDER BY year, month
    """)
    monthly['period'] = monthly['month_name'] + ' ' \
                      + monthly['year'].astype(str)

    fig = go.Figure()
    fig.add_trace(go.Scatter(
        x=monthly['period'], y=monthly['actual'],
        name='Actual', line=dict(color='#2196F3', width=2.5)
    ))
    fig.add_trace(go.Scatter(
        x=monthly['period'], y=monthly['forecast'],
        name='Forecast', line=dict(color='#FF9800', width=2,
                                   dash='dash')
    ))
    # Train/test divider
    fig.add_vline(
        x=12,
        line_dash='dot',
        line_color='red'
    )
    fig.update_layout(
        height=420, hovermode='x unified',
        xaxis_title='Month',
        yaxis_title='Total Revenue (€)',
        legend=dict(orientation='h', y=1.1),
        margin=dict(l=0, r=0, t=40, b=0)
    )
    st.plotly_chart(fig, use_container_width=True)

    # Bottom row
    col_l, col_r = st.columns(2)

    with col_l:
        st.subheader("🏪 Sales by Store Type")
        store_type = sql("""
            SELECT
                "StoreType"                     AS store_type,
                COUNT(DISTINCT "Store")         AS num_stores,
                ROUND(AVG("Sales"))             AS avg_daily_sales,
                ROUND(AVG("Sales") FILTER
                    (WHERE "Promo"=1))          AS avg_promo_sales,
                ROUND(AVG("Sales") FILTER
                    (WHERE "Promo"=0))          AS avg_no_promo_sales
            FROM sales
            GROUP BY "StoreType"
            ORDER BY avg_daily_sales DESC
        """)
        fig2 = px.bar(
            store_type,
            x='store_type', y='avg_daily_sales',
            color='store_type',
            text='num_stores',
            color_discrete_sequence=px.colors.qualitative.Set2,
            labels={'store_type': 'Store Type',
                    'avg_daily_sales': 'Avg Daily Sales (€)'}
        )
        fig2.update_traces(
            texttemplate='%{text} stores',
            textposition='outside'
        )
        fig2.update_layout(
            height=320, showlegend=False,
            margin=dict(l=0, r=0, t=20, b=0)
        )
        st.plotly_chart(fig2, use_container_width=True)

    with col_r:
        st.subheader("🎯 Model Scorecard")
        scorecard = sql("""
            SELECT
                model, rmse, mae, mape,
                mean_bias, coverage_95,
                overall_rank
            FROM v_model_scorecard
            ORDER BY overall_rank
        """)
        st.dataframe(
            scorecard,
            use_container_width=True,
            hide_index=True,
            column_config={
                'rmse':         st.column_config.NumberColumn('RMSE', format='%d'),
                'mae':          st.column_config.NumberColumn('MAE',  format='%d'),
                'mape':         st.column_config.NumberColumn('MAPE', format='%.2f%%'),
                'mean_bias':    st.column_config.NumberColumn('Bias', format='%d'),
                'coverage_95':  st.column_config.NumberColumn('95% Coverage', format='%.1f%%'),
                'overall_rank': st.column_config.NumberColumn('Rank')
            }
        )
        best = scorecard.iloc[0]
        st.success(
            f"🏆 **{best['model']}** wins · "
            f"RMSE {int(best['rmse']):,} · "
            f"MAPE {float(best['mape']):.2f}%"
        )

# ══════════════════════════════════════════════════════════════════════════════
# PAGE 2 — SALES TRENDS
# ══════════════════════════════════════════════════════════════════════════════
elif page == "📈 Sales Trends":
    st.title("📈 Sales Trends & EDA")
    st.divider()

    tab1, tab2, tab3 = st.tabs([
        "Seasonality", "Promo Impact", "Store Comparison"
    ])

    with tab1:
        st.subheader("Monthly Seasonality Index")
        seas = sql("""
            WITH overall AS (
                SELECT AVG("Sales") AS grand_avg FROM sales
            ),
            monthly AS (
                SELECT month, month_name,
                       AVG("Sales") AS month_avg
                FROM sales
                GROUP BY month, month_name
            )
            SELECT
                m.month, m.month_name,
                ROUND(m.month_avg)                              AS avg_sales,
                ROUND(100.0*m.month_avg/o.grand_avg,1)         AS seasonality_index
            FROM monthly m, overall o
            ORDER BY m.month
        """)
        fig3 = px.bar(
            seas, x='month_name', y='seasonality_index',
            color='seasonality_index',
            color_continuous_scale='RdYlGn',
            text='seasonality_index',
            labels={'month_name': 'Month',
                    'seasonality_index': 'Index (100=average)'}
        )
        fig3.add_hline(y=100, line_dash='dash',
                       line_color='gray',
                       annotation_text='Average (100)')
        fig3.update_traces(texttemplate='%{text}',
                           textposition='outside')
        fig3.update_layout(height=380,
                           margin=dict(l=0,r=0,t=20,b=0),
                           coloraxis_showscale=False)
        st.plotly_chart(fig3, use_container_width=True)

        st.subheader("Day of Week Pattern")
        dow = sql("""
            SELECT
                "DayOfWeek",
                TRIM(TO_CHAR("Date",'Day')) AS day_name,
                ROUND(AVG("Sales"))          AS avg_sales,
                ROUND(AVG("Customers"))      AS avg_customers
            FROM sales
            GROUP BY "DayOfWeek",
                     TRIM(TO_CHAR("Date",'Day'))
            ORDER BY "DayOfWeek"
        """)
        fig4 = px.bar(
            dow, x='day_name', y='avg_sales',
            color='avg_sales',
            color_continuous_scale='Blues',
            text='avg_sales',
            labels={'day_name': 'Day',
                    'avg_sales': 'Avg Sales (€)'}
        )
        fig4.update_traces(texttemplate='€%{text:,}',
                           textposition='outside')
        fig4.update_layout(height=350,
                           margin=dict(l=0,r=0,t=20,b=0),
                           coloraxis_showscale=False)
        st.plotly_chart(fig4, use_container_width=True)

    with tab2:
        st.subheader("Promo Lift by Store Type")
        promo = sql("""
            SELECT "StoreType", "Assortment",
                   avg_sales_promo, avg_sales_no_promo,
                   promo_lift_pct, num_stores
            FROM v_promo_effectiveness
            ORDER BY promo_lift_pct DESC
        """)
        fig5 = px.bar(
            promo, x='StoreType',
            y=['avg_sales_promo', 'avg_sales_no_promo'],
            barmode='group',
            color_discrete_map={
                'avg_sales_promo':    '#4CAF50',
                'avg_sales_no_promo': '#F44336'
            },
            labels={'value': 'Avg Sales (€)',
                    'variable': 'Condition',
                    'StoreType': 'Store Type'}
        )
        fig5.update_layout(height=380,
                           margin=dict(l=0,r=0,t=20,b=0))
        st.plotly_chart(fig5, use_container_width=True)
        st.dataframe(promo[['StoreType','Assortment',
                             'promo_lift_pct','num_stores']],
                     use_container_width=True,
                     hide_index=True)

    with tab3:
        st.subheader("Top 20 Stores by Avg Daily Sales")
        top_stores = sql("""
            SELECT "Store", "StoreType", "Assortment",
                   avg_daily_sales, total_sales,
                   rank_by_avg_sales, percentile
            FROM v_store_performance
            ORDER BY rank_by_avg_sales
            LIMIT 20
        """)
        fig6 = px.bar(
            top_stores,
            x='Store', y='avg_daily_sales',
            color='StoreType',
            hover_data=['Assortment','percentile'],
            labels={'Store': 'Store ID',
                    'avg_daily_sales': 'Avg Daily Sales (€)'}
        )
        fig6.update_layout(height=380,
                           margin=dict(l=0,r=0,t=20,b=0))
        st.plotly_chart(fig6, use_container_width=True)

# ══════════════════════════════════════════════════════════════════════════════
# PAGE 3 — FORECAST
# ══════════════════════════════════════════════════════════════════════════════
elif page == "🔮 Forecast":
    st.title("🔮 Sales Forecast")
    st.divider()

    store_id = st.selectbox(
        "Select Store",
        options=list(range(1, 1116)),
        index=0
    )

    store_data = sql(f"""
        SELECT
            "Date"::TEXT AS "Date", actual_sales,
            ensemble_forecast, ts_forecast,
            ma_forecast, upper_95, lower_95,
            ape, split
        FROM t_final_forecast
        WHERE "Store" = {store_id}
        ORDER BY "Date"
    """)

    store_info = sql(f"""
        SELECT store_segment, inventory_risk,
               avg_mape, pct_excellent,
               avg_daily_forecast, alert_level
        FROM t_store_summary
        WHERE "Store" = {store_id}
    """).iloc[0]

    # Store info pills
    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Segment",        store_info['store_segment'])
    c2.metric("Risk",           store_info['inventory_risk'])
    c3.metric("Avg MAPE",       f"{float(store_info['avg_mape']):.1f}%")
    c4.metric("Excellent Days", f"{float(store_info['pct_excellent']):.1f}%")

    st.divider()

    # Forecast chart
    fig7 = go.Figure()
    fig7.add_trace(go.Scatter(
        x=store_data['Date'],
        y=store_data['actual_sales'],
        name='Actual', line=dict(color='#2196F3', width=1.5)
    ))
    fig7.add_trace(go.Scatter(
        x=store_data['Date'],
        y=store_data['ensemble_forecast'],
        name='Ensemble Forecast',
        line=dict(color='#FF9800', width=2, dash='dash')
    ))
    fig7.add_trace(go.Scatter(
        x=store_data['Date'],
        y=store_data['upper_95'],
        name='95% Upper',
        line=dict(color='rgba(255,152,0,0.2)', width=0),
        showlegend=False
    ))
    fig7.add_trace(go.Scatter(
        x=store_data['Date'],
        y=store_data['lower_95'],
        name='95% Confidence Interval',
        fill='tonexty',
        fillcolor='rgba(255,152,0,0.15)',
        line=dict(color='rgba(255,152,0,0.2)', width=0)
    ))
    fig7.add_vline(
        x='2015-01-01',
        line_dash='dot',
        line_color='red'
    )
    fig7.update_layout(
        height=450, hovermode='x unified',
        xaxis_title='Date',
        yaxis_title='Sales (€)',
        legend=dict(orientation='h', y=1.1),
        margin=dict(l=0, r=0, t=40, b=0)
    )
    st.plotly_chart(fig7, use_container_width=True)

    # Error distribution
    col_l, col_r = st.columns(2)
    with col_l:
        st.subheader("Forecast Error Distribution")
        test_data = store_data[store_data['split']=='test']
        fig8 = px.histogram(
            test_data, x='ape', nbins=20,
            color_discrete_sequence=['#FF9800'],
            labels={'ape': 'Absolute % Error'}
        )
        fig8.add_vline(x=float(store_info['avg_mape']),
                       line_dash='dash', line_color='red',
                       annotation_text=f"MAPE: {float(store_info['avg_mape']):.1f}%")
        fig8.update_layout(height=300,
                           margin=dict(l=0,r=0,t=20,b=0))
        st.plotly_chart(fig8, use_container_width=True)

    with col_r:
        st.subheader("Model Blend Weights")
        blend = sql(f"""
            SELECT ts_blend_weight, ma_blend_weight
            FROM t_final_forecast
            WHERE "Store" = {store_id}
            LIMIT 1
        """).iloc[0]
        fig9 = px.pie(
            values=[float(blend['ts_blend_weight']),
                    float(blend['ma_blend_weight'])],
            names=['Trend+Seasonal', 'DOW_AVG'],
            color_discrete_sequence=['#4CAF50','#2196F3']
        )
        fig9.update_layout(height=300,
                           margin=dict(l=0,r=0,t=20,b=0))
        st.plotly_chart(fig9, use_container_width=True)

# ══════════════════════════════════════════════════════════════════════════════
# PAGE 4 — STORE ANALYSIS
# ══════════════════════════════════════════════════════════════════════════════
elif page == "🏪 Store Analysis":
    st.title("🏪 Store Analysis")
    st.divider()

    # Scatter: avg sales vs forecast accuracy
    scatter_data = sql("""
        SELECT "Store", "StoreType", "Assortment",
               avg_daily_forecast, avg_mape,
               store_segment, inventory_risk,
               days_of_stock, alert_level
        FROM t_store_summary
    """)

    st.subheader("Store Forecast Accuracy vs Sales Volume")
    fig10 = px.scatter(
        scatter_data,
        x='avg_daily_forecast', y='avg_mape',
        color='store_segment',
        symbol='StoreType',
        hover_data=['Store','Assortment',
                    'days_of_stock','alert_level'],
        labels={
            'avg_daily_forecast': 'Avg Daily Forecast (€)',
            'avg_mape': 'MAPE (%)',
            'store_segment': 'Segment'
        },
        color_discrete_sequence=px.colors.qualitative.Set2
    )
    fig10.update_layout(height=450,
                        margin=dict(l=0,r=0,t=20,b=0))
    st.plotly_chart(fig10, use_container_width=True)

    # Segment summary table
    st.subheader("Performance by Segment")
    seg_summary = sql("""
        SELECT
            store_segment,
            COUNT(*)                                    AS stores,
            ROUND(AVG(avg_daily_forecast)::NUMERIC)     AS avg_forecast,
            ROUND(AVG(avg_mape)::NUMERIC,1)             AS avg_mape,
            ROUND(AVG(safety_stock)::NUMERIC)           AS avg_safety_stock,
            ROUND(AVG(days_of_stock)::NUMERIC,1)        AS avg_days_stock,
            COUNT(*) FILTER (WHERE
                alert_level LIKE 'WARNING%')            AS warning_stores
        FROM t_store_summary
        GROUP BY store_segment
        ORDER BY avg_forecast DESC
    """)
    st.dataframe(seg_summary,
                 use_container_width=True,
                 hide_index=True)

# ══════════════════════════════════════════════════════════════════════════════
# PAGE 5 — INVENTORY
# ══════════════════════════════════════════════════════════════════════════════
elif page == "📦 Inventory":
    st.title("📦 Inventory Intelligence")
    st.divider()

    # Alert summary
    st.subheader("🚨 Reorder Alert Summary")
    alerts = sql("""
        SELECT
            alert_level,
            COUNT(*)::INTEGER                           AS num_stores,
            ROUND(AVG(days_of_stock)::NUMERIC,1)        AS avg_days,
            ROUND(AVG(velocity_ratio::NUMERIC),2)       AS avg_velocity,
            ROUND(AVG(last_7d_mape::NUMERIC),1)         AS avg_mape
        FROM t_store_summary
        GROUP BY alert_level
        ORDER BY num_stores DESC
    """)
    fig11 = px.bar(
        alerts, x='alert_level', y='num_stores',
        color='alert_level',
        color_discrete_map={
            'CRITICAL - Order immediately': '#F44336',
            'WARNING  - Order within 24hrs': '#FF9800',
            'WATCH    - Demand surging':     '#FFC107',
            'MONITOR  - Reorder soon':       '#2196F3',
            'OK       - Stock sufficient':   '#4CAF50'
        },
        text='num_stores',
        labels={'alert_level': 'Alert', 'num_stores': 'Stores'}
    )
    fig11.update_traces(textposition='outside')
    fig11.update_layout(height=350, showlegend=False,
                        margin=dict(l=0,r=0,t=20,b=0))
    st.plotly_chart(fig11, use_container_width=True)

    # Top stores needing attention
    st.subheader("⚠️ Stores Needing Immediate Attention")
    urgent = sql("""
        SELECT "Store", "StoreType", alert_level,
               ROUND(days_of_stock::NUMERIC,1)      AS days_of_stock,
               ROUND(velocity_ratio::NUMERIC,2)     AS velocity_ratio,
               recommended_order_qty::INTEGER       AS recommended_order_qty,
               ROUND(avg_mape::NUMERIC,1)           AS avg_mape,
               store_segment
        FROM t_store_summary
        WHERE alert_level LIKE 'WARNING%'
           OR alert_level LIKE 'WATCH%'
        ORDER BY days_of_stock ASC
        LIMIT 20
    """)
    st.dataframe(urgent,
                 use_container_width=True,
                 hide_index=True)
   
    # Inventory risk distribution
    st.subheader("Risk Distribution by Store Type")
    risk_dist = sql("""
        SELECT
            "StoreType",
            inventory_risk,
            COUNT(*)::INTEGER AS num_stores
        FROM t_store_summary
        GROUP BY "StoreType", inventory_risk
        ORDER BY "StoreType", inventory_risk
    """)
    fig12 = px.bar(
        risk_dist,
        x='StoreType', y='num_stores',
        color='inventory_risk',
        barmode='stack',
        color_discrete_map={
            'Low risk':    '#4CAF50',
            'Medium risk': '#FF9800',
            'High risk':   '#F44336'
        },
        labels={'StoreType': 'Store Type',
                'num_stores': 'Number of Stores'}
    )
    fig12.update_layout(height=350,
                        margin=dict(l=0,r=0,t=20,b=0))
    st.plotly_chart(fig12, use_container_width=True)

# ══════════════════════════════════════════════════════════════════════════════
# PAGE 6 — MODEL PERFORMANCE
# ══════════════════════════════════════════════════════════════════════════════
elif page == "🎯 Model Performance":
    st.title("🎯 Model Performance")
    st.divider()

    # Scorecard
    st.subheader("Model Comparison Scorecard")
    scorecard = sql("""
        SELECT model, rmse, mae, mape,
               mean_bias, coverage_95, overall_rank
        FROM v_model_scorecard
        ORDER BY overall_rank
    """)
    st.dataframe(scorecard,
                 use_container_width=True,
                 hide_index=True)
    st.divider()

    # RMSE comparison chart
    fig13 = px.bar(
        scorecard, x='model', y='rmse',
        color='model',
        text='rmse',
        color_discrete_sequence=px.colors.qualitative.Set2,
        labels={'model': 'Model', 'rmse': 'RMSE'}
    )
    fig13.update_traces(texttemplate='%{text:,}',
                        textposition='outside')
    fig13.update_layout(height=350, showlegend=False,
                        margin=dict(l=0,r=0,t=20,b=0))
    st.plotly_chart(fig13, use_container_width=True)

    # Error by month
    st.subheader("Forecast Error by Month (Test Set)")
    monthly_err = sql("""
        SELECT
            EXTRACT(YEAR  FROM "Date")::INTEGER AS year,
            EXTRACT(MONTH FROM "Date")::INTEGER AS month,
            TO_CHAR(MIN("Date"),'Mon YYYY')     AS period,
            ROUND(AVG(ape)::NUMERIC,2)          AS avg_mape,
            ROUND(SQRT(AVG(POWER(
                ensemble_error,2)))::NUMERIC)   AS rmse
        FROM t_final_forecast
        WHERE split = 'test'
        GROUP BY EXTRACT(YEAR  FROM "Date"),
                 EXTRACT(MONTH FROM "Date")
        ORDER BY year, month
    """)

    fig14 = px.line(
        monthly_err, x='period',
        y=['avg_mape', 'rmse'],
        markers=True,
        labels={'value': 'Error',
                'variable': 'Metric',
                'period': 'Month'}
    )
    fig14.update_layout(height=350,
                        margin=dict(l=0,r=0,t=20,b=0))
    st.plotly_chart(fig14, use_container_width=True)

    # Forecast quality distribution
    st.subheader("Forecast Quality Distribution (Test Set)")
    quality = sql("""
        SELECT
            CASE
                WHEN ape < 10  THEN '1. Excellent (<10%)'
                WHEN ape < 20  THEN '2. Good (10-20%)'
                WHEN ape < 30  THEN '3. Fair (20-30%)'
                ELSE                '4. Poor (>30%)'
            END                                     AS quality_band,
            COUNT(*)::INTEGER                       AS num_forecasts,
            ROUND((100.0 * COUNT(*)
                / SUM(COUNT(*)) OVER())::NUMERIC
            ,1)                                     AS pct
        FROM t_final_forecast
        WHERE split = 'test'
        GROUP BY quality_band
        ORDER BY quality_band
    """)
    fig15 = px.pie(
        quality, values='num_forecasts',
        names='quality_band',
        color_discrete_sequence=[
            '#4CAF50','#8BC34A','#FF9800','#F44336'
        ]
    )
    fig15.update_layout(height=350,
                        margin=dict(l=0,r=0,t=20,b=0))
    st.plotly_chart(fig15, use_container_width=True)