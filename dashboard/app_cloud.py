import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import os

st.set_page_config(
    page_title="Retail Forecasting | Rossmann",
    page_icon="🛒",
    layout="wide",
    initial_sidebar_state="expanded"
)

# ── Load data from CSV files (no database needed) ─────────────────────────────
DATA_DIR = os.path.join(os.path.dirname(__file__), "data")

@st.cache_data
def load(filename):
    return pd.read_csv(os.path.join(DATA_DIR, filename))

kpi         = load("kpi_summary.csv").iloc[0]
store_sum   = load("store_summary.csv")
monthly     = load("monthly_forecast.csv")
scorecard   = load("model_scorecard.csv")
promo       = load("promo_effectiveness.csv")
store_perf  = load("store_performance.csv")
forecast    = load("forecast_sample.csv")
alerts      = load("alerts.csv")

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

    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Total Stores",    f"{int(kpi['total_stores']):,}")
    c2.metric("Total Revenue",   f"€{int(kpi['total_revenue'])/1e9:.2f}B")
    c3.metric("Avg Daily Sales", f"€{int(kpi['avg_daily_sales']):,}")
    c4.metric("Max Single Day",  f"€{int(kpi['max_daily_sales']):,}")

    st.divider()

    c5, c6, c7, c8 = st.columns(4)
    c5.metric("Ensemble RMSE",        f"{int(kpi['ensemble_rmse']):,}")
    c6.metric("Ensemble MAPE",        f"{float(kpi['ensemble_mape']):.2f}%")
    c7.metric("Excellent Forecasts",  f"{float(kpi['pct_forecasts_excellent']):.1f}%")
    c8.metric("Stores Need Reorder",
              f"{int(kpi['stores_needing_reorder'])}",
              delta=f"{int(kpi['stores_demand_surging'])} surging",
              delta_color="inverse")

    st.divider()

    # Monthly revenue chart
    st.subheader("📊 Monthly Revenue — Actual vs Ensemble Forecast")
    monthly_agg = monthly.groupby(
        ['year','month','month_name','split']
    ).agg(
        actual=('actual_monthly_sales','sum'),
        forecast=('forecast_monthly_sales','sum')
    ).reset_index().sort_values(['year','month'])

    monthly_agg['period'] = (monthly_agg['month_name']
                           + ' ' + monthly_agg['year'].astype(str))

    fig = go.Figure()
    fig.add_trace(go.Scatter(
        x=monthly_agg['period'], y=monthly_agg['actual'],
        name='Actual', line=dict(color='#2196F3', width=2.5)
    ))
    fig.add_trace(go.Scatter(
        x=monthly_agg['period'], y=monthly_agg['forecast'],
        name='Forecast', line=dict(color='#FF9800',
                                   width=2, dash='dash')
    ))
    fig.update_layout(
        height=420, hovermode='x unified',
        xaxis_title='Month',
        yaxis_title='Total Revenue (€)',
        legend=dict(orientation='h', y=1.1),
        margin=dict(l=0, r=0, t=40, b=0)
    )
    st.plotly_chart(fig, use_container_width=True)

    col_l, col_r = st.columns(2)
    with col_l:
        st.subheader("🏪 Sales by Store Type")
        type_data = store_sum.groupby('StoreType').agg(
            num_stores=('Store','count'),
            avg_sales=('avg_daily_forecast','mean')
        ).reset_index()
        type_data['avg_sales'] = type_data['avg_sales'].round()
        fig2 = px.bar(
            type_data, x='StoreType', y='avg_sales',
            color='StoreType', text='num_stores',
            color_discrete_sequence=px.colors.qualitative.Set2
        )
        fig2.update_traces(
            texttemplate='%{text} stores',
            textposition='outside'
        )
        fig2.update_layout(height=320, showlegend=False,
                           margin=dict(l=0,r=0,t=20,b=0))
        st.plotly_chart(fig2, use_container_width=True)

    with col_r:
        st.subheader("🎯 Model Scorecard")
        st.dataframe(
            scorecard[['model','rmse','mae',
                        'mape','mean_bias','overall_rank']],
            use_container_width=True,
            hide_index=True
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
        st.subheader("Day of Week Pattern")
        dow_data = store_sum.copy()
        st.info(
            "Day-of-week analysis: Monday is peak trading day "
            "with highest avg sales. Sunday has fewest open stores."
        )

        st.subheader("Monthly Forecast by Year")
        monthly_yr = monthly.groupby(
            ['year','month','month_name']
        ).agg(actual=('actual_monthly_sales','sum')).reset_index()
        fig3 = px.line(
            monthly_yr, x='month', y='actual',
            color='year', markers=True,
            labels={'month':'Month','actual':'Total Sales (€)'},
            color_discrete_sequence=px.colors.qualitative.Set1
        )
        fig3.update_layout(height=380,
                           margin=dict(l=0,r=0,t=20,b=0))
        st.plotly_chart(fig3, use_container_width=True)

    with tab2:
        st.subheader("Promo Lift by Store Type")
        fig4 = px.bar(
            promo, x='StoreType',
            y=['avg_sales_promo','avg_sales_no_promo'],
            barmode='group',
            color_discrete_map={
                'avg_sales_promo':    '#4CAF50',
                'avg_sales_no_promo': '#F44336'
            },
            labels={'value':'Avg Sales (€)',
                    'variable':'Condition'}
        )
        fig4.update_layout(height=380,
                           margin=dict(l=0,r=0,t=20,b=0))
        st.plotly_chart(fig4, use_container_width=True)
        st.dataframe(
            promo[['StoreType','Assortment',
                   'promo_lift_pct','num_stores']],
            use_container_width=True,
            hide_index=True
        )

    with tab3:
        st.subheader("Top Stores by Avg Daily Sales")
        fig5 = px.bar(
            store_perf.head(20),
            x='Store', y='avg_daily_sales',
            color='StoreType',
            labels={'Store':'Store ID',
                    'avg_daily_sales':'Avg Daily Sales (€)'}
        )
        fig5.update_layout(height=380,
                           margin=dict(l=0,r=0,t=20,b=0))
        st.plotly_chart(fig5, use_container_width=True)

# ══════════════════════════════════════════════════════════════════════════════
# PAGE 3 — FORECAST
# ══════════════════════════════════════════════════════════════════════════════
elif page == "🔮 Forecast":
    st.title("🔮 Sales Forecast")
    st.divider()

    available_stores = sorted(forecast['Store'].unique())
    store_id = st.selectbox("Select Store", available_stores)

    store_data = forecast[forecast['Store'] == store_id].copy()
    store_data['Date'] = pd.to_datetime(store_data['Date'])
    store_info = store_sum[store_sum['Store'] == store_id]

    if len(store_info) > 0:
        info = store_info.iloc[0]
        c1, c2, c3, c4 = st.columns(4)
        c1.metric("Segment",        info['store_segment'])
        c2.metric("Risk",           info['inventory_risk'])
        c3.metric("Avg MAPE",       f"{float(info['avg_mape']):.1f}%")
        c4.metric("Alert",          info['alert_level'][:7])

    st.divider()

    fig6 = go.Figure()
    fig6.add_trace(go.Scatter(
        x=store_data['Date'],
        y=store_data['actual_sales'],
        name='Actual',
        line=dict(color='#2196F3', width=1.5)
    ))
    fig6.add_trace(go.Scatter(
        x=store_data['Date'],
        y=store_data['ensemble_forecast'],
        name='Ensemble Forecast',
        line=dict(color='#FF9800', width=2, dash='dash')
    ))
    fig6.add_trace(go.Scatter(
        x=store_data['Date'],
        y=store_data['upper_95'],
        name='95% Upper',
        line=dict(width=0),
        showlegend=False
    ))
    fig6.add_trace(go.Scatter(
        x=store_data['Date'],
        y=store_data['lower_95'],
        name='95% CI',
        fill='tonexty',
        fillcolor='rgba(255,152,0,0.15)',
        line=dict(width=0)
    ))
    fig6.update_layout(
        height=450, hovermode='x unified',
        xaxis_title='Date', yaxis_title='Sales (€)',
        legend=dict(orientation='h', y=1.1),
        margin=dict(l=0,r=0,t=40,b=0)
    )
    st.plotly_chart(fig6, use_container_width=True)

    st.info(
        "📌 Forecast data shown for stores 1-10. "
        "Full 1,115 store forecasts available in local deployment."
    )

# ══════════════════════════════════════════════════════════════════════════════
# PAGE 4 — STORE ANALYSIS
# ══════════════════════════════════════════════════════════════════════════════
elif page == "🏪 Store Analysis":
    st.title("🏪 Store Analysis")
    st.divider()

    st.subheader("Forecast Accuracy vs Sales Volume")
    fig7 = px.scatter(
        store_sum,
        x='avg_daily_forecast', y='avg_mape',
        color='store_segment',
        symbol='StoreType',
        hover_data=['Store','days_of_stock','alert_level'],
        labels={
            'avg_daily_forecast': 'Avg Daily Forecast (€)',
            'avg_mape': 'MAPE (%)',
            'store_segment': 'Segment'
        },
        color_discrete_sequence=px.colors.qualitative.Set2
    )
    fig7.update_layout(height=450,
                       margin=dict(l=0,r=0,t=20,b=0))
    st.plotly_chart(fig7, use_container_width=True)

    st.subheader("Performance by Segment")
    seg = store_sum.groupby('store_segment').agg(
        stores=('Store','count'),
        avg_forecast=('avg_daily_forecast','mean'),
        avg_mape=('avg_mape','mean'),
        avg_safety_stock=('safety_stock','mean'),
        avg_days_stock=('days_of_stock','mean')
    ).reset_index().round(1)
    seg = seg.sort_values('avg_forecast', ascending=False)
    st.dataframe(seg, use_container_width=True, hide_index=True)

# ══════════════════════════════════════════════════════════════════════════════
# PAGE 5 — INVENTORY
# ══════════════════════════════════════════════════════════════════════════════
elif page == "📦 Inventory":
    st.title("📦 Inventory Intelligence")
    st.divider()

    st.subheader("🚨 Reorder Alert Summary")
    fig8 = px.bar(
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
        labels={'alert_level':'Alert','num_stores':'Stores'}
    )
    fig8.update_traces(textposition='outside')
    fig8.update_layout(height=350, showlegend=False,
                       margin=dict(l=0,r=0,t=20,b=0))
    st.plotly_chart(fig8, use_container_width=True)

    st.subheader("⚠️ Stores Needing Attention")
    urgent = store_sum[
        store_sum['alert_level'].str.contains(
            'WARNING|WATCH', na=False
        )
    ][['Store','StoreType','alert_level',
       'days_of_stock','velocity_ratio',
       'recommended_order_qty','store_segment']
    ].sort_values('days_of_stock').head(20)
    st.dataframe(urgent, use_container_width=True,
                 hide_index=True)

    st.subheader("Risk Distribution by Store Type")
    risk = store_sum.groupby(
        ['StoreType','inventory_risk']
    ).size().reset_index(name='num_stores')
    fig9 = px.bar(
        risk, x='StoreType', y='num_stores',
        color='inventory_risk', barmode='stack',
        color_discrete_map={
            'Low risk':    '#4CAF50',
            'Medium risk': '#FF9800',
            'High risk':   '#F44336'
        }
    )
    fig9.update_layout(height=350,
                       margin=dict(l=0,r=0,t=20,b=0))
    st.plotly_chart(fig9, use_container_width=True)

# ══════════════════════════════════════════════════════════════════════════════
# PAGE 6 — MODEL PERFORMANCE
# ══════════════════════════════════════════════════════════════════════════════
elif page == "🎯 Model Performance":
    st.title("🎯 Model Performance")
    st.divider()

    st.subheader("Model Comparison Scorecard")
    st.dataframe(
        scorecard[['model','rmse','mae','mape',
                   'mean_bias','coverage_95','overall_rank']],
        use_container_width=True,
        hide_index=True
    )
    st.divider()

    fig10 = px.bar(
        scorecard, x='model', y='rmse',
        color='model', text='rmse',
        color_discrete_sequence=px.colors.qualitative.Set2
    )
    fig10.update_traces(texttemplate='%{text:,}',
                        textposition='outside')
    fig10.update_layout(height=350, showlegend=False,
                        margin=dict(l=0,r=0,t=20,b=0))
    st.plotly_chart(fig10, use_container_width=True)

    st.subheader("Monthly Forecast Accuracy (Test Set)")
    test = monthly[monthly['split']=='test'].copy()
    test_agg = test.groupby(
        ['year','month','month_name']
    ).agg(
        actual=('actual_monthly_sales','sum'),
        forecast=('forecast_monthly_sales','sum')
    ).reset_index()
    test_agg['mape'] = (
        abs(test_agg['actual'] - test_agg['forecast'])
        / test_agg['actual'] * 100
    ).round(2)
    test_agg['period'] = (test_agg['month_name']
                        + ' ' + test_agg['year'].astype(str))
    fig11 = px.bar(
        test_agg, x='period', y='mape',
        color='mape',
        color_continuous_scale='RdYlGn_r',
        text='mape',
        labels={'period':'Month','mape':'MAPE (%)'}
    )
    fig11.update_traces(texttemplate='%{text:.1f}%',
                        textposition='outside')
    fig11.update_layout(height=350,
                        coloraxis_showscale=False,
                        margin=dict(l=0,r=0,t=20,b=0))
    st.plotly_chart(fig11, use_container_width=True)

    st.subheader("Forecast Quality Distribution")
    quality_data = pd.DataFrame({
        'quality_band': ['Excellent (<10%)', 'Good (10-20%)',
                         'Fair (20-30%)', 'Poor (>30%)'],
        'pct': [37.8, 29.7, 16.6, 15.9]
    })
    fig12 = px.pie(
        quality_data, values='pct',
        names='quality_band',
        color_discrete_sequence=[
            '#4CAF50','#8BC34A','#FF9800','#F44336'
        ]
    )
    fig12.update_layout(height=350,
                        margin=dict(l=0,r=0,t=20,b=0))
    st.plotly_chart(fig12, use_container_width=True)