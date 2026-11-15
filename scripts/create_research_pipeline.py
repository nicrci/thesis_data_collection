import matplotlib.pyplot as plt
import matplotlib.patches as patches
from matplotlib import rcParams
import os

# Set font - using a clean sans-serif for a report-style look
rcParams['font.family'] = 'sans-serif'
rcParams['font.sans-serif'] = ['Arial', 'Helvetica', 'sans-serif']

def create_pipeline():
    # Academic / Light Report Palette
    BG_COLOR = '#ffffff'      # White background
    TEXT_COLOR = '#2c3e50'    # Dark gray/black text
    BORDER_COLOR = '#7f8c8d'  # Muted gray borders
    BOX_FILL = '#e8f6ff'      # Light blue fill
    LOGIC_FILL = '#fdf2e9'    # Light orange/cream for logic
    ARROW_COLOR = '#34495e'   # Darker gray for arrows
    
    # Set up the figure and axis
    fig, ax = plt.subplots(figsize=(14, 6), facecolor=BG_COLOR)
    ax.set_xlim(0, 10)
    ax.set_ylim(0, 5)
    ax.axis('off')

    # Box dimensions
    box_width = 2.9
    box_height = 2.2
    y_pos = 1.4

    # --- Stage 1: Infrastructure Investment Model ---
    box1 = patches.FancyBboxPatch((0.2, y_pos), box_width, box_height, boxstyle="round,pad=0.1", 
                                 fc=BOX_FILL, ec=BORDER_COLOR, lw=1.5, zorder=2)
    ax.add_patch(box1)
    
    ax.text(1.65, 3.1, "Infrastructure\nInvestment Model", 
            color=TEXT_COLOR, fontsize=16, fontweight='bold', ha='center', va='center', zorder=3)
    
    ax.text(1.65, 2.2, "Framework for identifying\ncapital variables and\nassessment parameters.", 
            color=TEXT_COLOR, fontsize=12, ha='center', va='center', zorder=3)

    # --- Arrow 1 ---
    ax.annotate("", xy=(3.45, 2.5), xytext=(3.15, 2.5),
                arrowprops=dict(arrowstyle="->", color=ARROW_COLOR, lw=2, mutation_scale=20),
                zorder=2)

    # --- Stage 2: Governance, Financing & Implementation ---
    box2 = patches.FancyBboxPatch((3.55, y_pos), box_width, box_height, boxstyle="round,pad=0.1", 
                                 fc=BOX_FILL, ec=BORDER_COLOR, lw=1.5, zorder=2)
    ax.add_patch(box2)
    
    ax.text(5.0, 3.1, "Governance, Financing\n& Implementation", 
            color=TEXT_COLOR, fontsize=16, fontweight='bold', ha='center', va='center', zorder=3)
    
    ax.text(5.0, 2.2, "Mechanisms for oversight,\nfunding structures, and\nproject delivery systems.", 
            color=TEXT_COLOR, fontsize=12, ha='center', va='center', zorder=3)

    # --- Arrow 2 ---
    ax.annotate("", xy=(6.8, 2.5), xytext=(6.5, 2.5),
                arrowprops=dict(arrowstyle="->", color=ARROW_COLOR, lw=2, mutation_scale=20),
                zorder=2)

    # --- Stage 3: Institutional Logic ---
    box3 = patches.FancyBboxPatch((6.9, y_pos), box_width, box_height, boxstyle="round,pad=0.1", 
                                 fc=LOGIC_FILL, ec=BORDER_COLOR, lw=1.5, zorder=2)
    ax.add_patch(box3)
    
    ax.text(8.35, 3.1, "Institutional Logic", 
            color=TEXT_COLOR, fontsize=16, fontweight='bold', ha='center', va='center', zorder=3)
    
    ax.text(8.35, 2.2, "The belief systems and\nnorms guiding strategic\ndecision-making.", 
            color=TEXT_COLOR, fontsize=12, ha='center', va='center', zorder=3)

    # --- Title ---
    plt.text(5, 4.5, "Research Analysis Pipeline", 
             fontsize=22, fontweight='bold', ha='center', color=TEXT_COLOR)
    
    plt.text(5, 4.2, "Proposed Structural Framework for Infrastructure Projects", 
             fontsize=14, ha='center', color=ARROW_COLOR)

    # Save the figure
    plt.savefig('research_pipeline.png', dpi=300, bbox_inches='tight', pad_inches=0.4, facecolor=BG_COLOR)
    print("Pipeline diagram updated with 3 stages and larger text: research_pipeline.png")

if __name__ == "__main__":
    create_pipeline()
