import PyPDF2
import os

pdf_dir = r"C:\Users\HP\Desktop\SEM 6\SGP\Task"
files = ["Pr7.pdf", "Pr8.pdf"]

for f in files:
    path = os.path.join(pdf_dir, f)
    if os.path.exists(path):
        print(f"--- {f} ---")
        try:
            reader = PyPDF2.PdfReader(path)
            for i, page in enumerate(reader.pages):
                if i > 2: break # read only first 3 pages
                print(page.extract_text()[:500])
        except Exception as e:
            print(f"Error reading {f}: {e}")
