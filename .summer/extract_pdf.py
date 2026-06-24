import os
import traceback

PDF_PATH = r"c:\Users\david\OneDrive\Desktop\Sun Tzu and Infernal Curse Game AI.pdf"
OUT_PATH = os.path.join(os.path.dirname(__file__), "sun_tzu_extract.txt")

lines: list[str] = []
lines.append(f"exists={os.path.exists(PDF_PATH)}")
if os.path.exists(PDF_PATH):
    lines.append(f"size={os.path.getsize(PDF_PATH)}")
    try:
        import fitz

        doc = fitz.open(PDF_PATH)
        lines.append(f"pages={doc.page_count}")
        for index in range(doc.page_count):
            lines.append(f"--- PAGE {index + 1} ---")
            lines.append(doc[index].get_text())
    except Exception:
        lines.append(traceback.format_exc())
        try:
            from pypdf import PdfReader

            reader = PdfReader(PDF_PATH)
            lines.append(f"pypdf_pages={len(reader.pages)}")
            for index, page in enumerate(reader.pages):
                lines.append(f"--- PAGE {index + 1} ---")
                lines.append(page.extract_text() or "")
        except Exception:
            lines.append(traceback.format_exc())

with open(OUT_PATH, "w", encoding="utf-8") as handle:
    handle.write("\n".join(lines))