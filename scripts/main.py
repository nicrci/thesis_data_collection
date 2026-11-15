from contextlib import asynccontextmanager
from fastapi import FastAPI, Query, Request, HTTPException
from fastapi.responses import HTMLResponse, StreamingResponse, FileResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
import database
import fetch_data
import pandas as pd
import matplotlib.pyplot as plt
import io
import os
import openpyxl
import subprocess
import glob

R_SCRIPT = "analysis.R"
R_EXEC   = r"C:\Program Files\R\R-4.5.1\bin\Rscript.exe"
R_PLOTS_DIR = os.path.join("static", "r_plots")

def set_journal_style():
    """Sets Matplotlib parameters to match journal publication standards."""
    plt.style.use('seaborn-v0_8-whitegrid')
    plt.rcParams.update({
        'font.family': 'sans-serif',
        'font.sans-serif': ['Arial', 'Helvetica', 'DejaVu Sans'],
        'font.size': 8,
        'axes.titlesize': 10,
        'axes.labelsize': 8,
        'xtick.labelsize': 7,
        'ytick.labelsize': 7,
        'legend.fontsize': 7,
        'figure.titlesize': 10,
        'figure.facecolor': 'white',
        'axes.facecolor': 'white',
        'axes.edgecolor': '#374151',
        'axes.labelcolor': '#111827',
        'text.color': '#111827',
        'grid.color': '#e5e7eb',
        'grid.linewidth': 0.5,
        'axes.spines.top': False,
        'axes.spines.right': False,
        'savefig.dpi': 300,
        'figure.autolayout': True
    })

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Seed the database with mock data if it is empty."""
    database.init_db()
    if not database.get_unique_values("country"):
        df = fetch_data.fetch_cgit_data()
        database.load_data_from_dataframe(df)
    yield

app = FastAPI(title="China Global Investment Tracker", lifespan=lifespan)

# Ensure templates directory exists
os.makedirs("templates", exist_ok=True)
os.makedirs("static", exist_ok=True)

templates = Jinja2Templates(directory="templates")
app.mount("/static", StaticFiles(directory="static"), name="static")

@app.get("/", response_class=HTMLResponse)
async def read_root(request: Request):
    countries = database.get_unique_values("country")
    regions = database.get_unique_values("region")
    sectors = database.get_unique_values("sector")
    years = database.get_unique_values("year")
    return templates.TemplateResponse(
        "index.html",
        {"request": request, "countries": countries, "regions": regions, "sectors": sectors, "years": sorted(years, reverse=True)}
    )

@app.get("/api/data")
async def get_data(
    country: str = Query(None),
    region: str = Query(None),
    sector: str = Query(None),
    year: int = Query(None)
):
    filters = {k: v for k, v in {"country": country, "region": region, "sector": sector, "year": year}.items() if v is not None and v != ""}
    data = database.search_data(filters)
    return data

@app.get("/api/export")
async def export_data(
    country: str = Query(None),
    region: str = Query(None),
    sector: str = Query(None),
    year: int = Query(None)
):
    filters = {k: v for k, v in {"country": country, "region": region, "sector": sector, "year": year}.items() if v is not None and v != ""}
    data = database.search_data(filters)
    
    df = pd.DataFrame(data)
    
    # Create the CSV response
    stream = io.StringIO()
    df.to_csv(stream, index=False)
    
    response = StreamingResponse(iter([stream.getvalue()]), media_type="text/csv")
    response.headers["Content-Disposition"] = "attachment; filename=investments_data.csv"
    
    return response

@app.get("/api/export/excel")
async def export_excel(
    country: str = Query(None),
    region: str = Query(None),
    sector: str = Query(None),
    year: int = Query(None)
):
    filters = {k: v for k, v in {"country": country, "region": region, "sector": sector, "year": year}.items() if v is not None and v != ""}
    data = database.search_data(filters)

    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Investments"

    if data:
        headers = list(data[0].keys())
        ws.append(headers)
        for row in data:
            ws.append([row.get(h) for h in headers])
    else:
        ws.append(["No data found"])

    stream = io.BytesIO()
    wb.save(stream)
    stream.seek(0)

    response = StreamingResponse(
        iter([stream.read()]),
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )
    response.headers["Content-Disposition"] = "attachment; filename=investments_data.xlsx"
    return response

@app.get("/api/plots/sector")
async def plot_sector(
    country: str = Query(None),
    region: str = Query(None),
    sector: str = Query(None),
    year: int = Query(None)
):
    filters = {k: v for k, v in {"country": country, "region": region, "sector": sector, "year": year}.items() if v is not None and v != ""}
    data = database.search_data(filters)
    
    df = pd.DataFrame(data)
    
    set_journal_style()
    plt.figure(figsize=(4, 5))
    if df.empty:
        plt.text(0.5, 0.5, "No Data Available", ha='center', va='center')
    else:
        sector_counts = df['sector'].value_counts()
        # Use a colormap for variety but keep it journal-safe
        colors = plt.cm.viridis(pd.Series(range(len(sector_counts))) / len(sector_counts))
        sector_counts.plot(kind='barh', color=colors, edgecolor='none')
        plt.title('Investment projects by sector')
        plt.xlabel('Number of projects')
        plt.ylabel(None)
        plt.gca().invert_yaxis()

    buf = io.BytesIO()
    plt.savefig(buf, format="png", bbox_inches='tight')
    buf.seek(0)
    plt.close()
    
    return StreamingResponse(buf, media_type="image/png")

@app.get("/api/map-data")
async def get_map_data(
    country: str = Query(None),
    region: str = Query(None),
    sector: str = Query(None),
    year: int = Query(None)
):
    """Returns aggregated investment totals by country for the world map."""
    filters = {k: v for k, v in {"country": country, "region": region, "sector": sector, "year": year}.items() if v is not None and v != ""}
    data = database.search_data(filters)
    df = pd.DataFrame(data)
    if df.empty:
        return []
    totals = (
        df.groupby("country")["amount"]
        .sum()
        .sort_values(ascending=False)
        .reset_index()
    )
    totals.columns = ["country", "total"]
    totals["total"] = totals["total"].round(2)
    return totals.to_dict(orient="records")

@app.get("/api/plots/country")
async def plot_country(
    country: str = Query(None),
    region: str = Query(None),
    sector: str = Query(None),
    year: int = Query(None)
):
    filters = {k: v for k, v in {"country": country, "region": region, "sector": sector, "year": year}.items() if v is not None and v != ""}
    data = database.search_data(filters)
    
    df = pd.DataFrame(data)
    
    set_journal_style()
    plt.figure(figsize=(4, 5))
    if df.empty:
        plt.text(0.5, 0.5, "No Data Available", ha='center', va='center')
    else:
        top_countries = df['country'].value_counts().head(15)
        colors = plt.cm.magma(pd.Series(range(len(top_countries))) / len(top_countries))
        top_countries.plot(kind='barh', color=colors, edgecolor='none')
        plt.title('Top 15 destination countries')
        plt.xlabel('Number of projects')
        plt.ylabel(None)
        plt.gca().invert_yaxis()

    buf = io.BytesIO()
    plt.savefig(buf, format="png", bbox_inches='tight')
    buf.seek(0)
    plt.close()
    
    return StreamingResponse(buf, media_type="image/png")


@app.post("/api/r-analysis")
async def run_r_analysis():
    """Run the R tidyverse analysis script and return generated plot filenames."""
    if not os.path.exists(R_EXEC):
        raise HTTPException(status_code=503, detail="R executable not found on this server.")
    if not os.path.exists(R_SCRIPT):
        raise HTTPException(status_code=503, detail="analysis.R not found.")

    os.makedirs(R_PLOTS_DIR, exist_ok=True)

    try:
        result = subprocess.run(
            [R_EXEC, R_SCRIPT, database.DB_NAME],
            capture_output=True,
            text=True,
            timeout=120
        )
        if result.returncode != 0:
            raise HTTPException(status_code=500, detail=f"R script failed: {result.stderr[-2000:]}")
    except subprocess.TimeoutExpired:
        raise HTTPException(status_code=504, detail="R analysis timed out.")

    # Collect generated plot files
    plots = sorted(glob.glob(os.path.join(R_PLOTS_DIR, "*.png")))
    plot_urls = [f"/static/r_plots/{os.path.basename(p)}" for p in plots]
    return {"status": "ok", "plots": plot_urls, "log": result.stdout[-1000:]}


@app.get("/api/r-analysis/status")
async def r_analysis_status():
    """Check whether R plots already exist (pre-generated)."""
    plots = sorted(glob.glob(os.path.join(R_PLOTS_DIR, "*.png")))
    plot_urls = [f"/static/r_plots/{os.path.basename(p)}" for p in plots]
    return {"plots": plot_urls}
