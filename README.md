# trade_reconciler
📊 Trade Reconciler
A lightweight trade reconciliation system that compares trade data across sources and identifies mismatches, missing records, and inconsistencies.

🚀 Overview
Trade Reconciler helps ensure data integrity by:

Comparing trade records between systems

Identifying unmatched trades

Detecting quantity/price mismatches

Generating reconciliation reports

Built to simulate real-world financial data validation workflows.

🛠 Tech Stack
Python 3.x

Pandas

CSV / Excel file handling

(Adjust this if you're using something else.)

📂 Project Structure
trade_reconciler/
│
├── data/               # Input trade files
├── output/             # Reconciliation results
├── reconciler.py       # Core reconciliation logic
├── requirements.txt    # Dependencies
└── README.md
⚙️ Installation
Clone the repository:

git clone https://github.com/brahmakshatriya/trade_reconciler.git
cd trade_reconciler
Install dependencies:

pip install -r requirements.txt
▶️ Usage
Run the reconciler:

python reconciler.py
Output will be generated in the output/ directory.

🧠 Features
✅ Exact trade matching

⚠️ Mismatch detection

❌ Missing trade identification

📑 Clean output reporting

🔮 Future Improvements
Web dashboard interface

Database integration

Automated scheduled reconciliation

Logging and audit trail

👨‍💻 Author
Brahmakshatriya
