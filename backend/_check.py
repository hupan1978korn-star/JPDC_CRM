import sqlite3
c = sqlite3.connect(r"C:\Users\Korn\Desktop\JPDC_CRM_安装包\backend\jpdc.db").cursor()
c.execute("SELECT tower, COUNT(*) FROM units GROUP BY tower")
print("Units:", [(r[0], r[1]) for r in c.fetchall()])
c.execute("SELECT status, COUNT(*) FROM units GROUP BY status")
for r in c.fetchall():
    print(f"  {r[1]:>5}  {r[0][:30]}")
c.execute("SELECT COUNT(*) FROM sold_clients")
print("Sold clients:", c.fetchone()[0])
c.execute("SELECT COUNT(*) FROM overdue_warnings")
print("Overdue:", c.fetchone()[0])
c.execute("SELECT COUNT(*) FROM returned_units")
print("Returned:", c.fetchone()[0])
c.execute("SELECT key, value FROM sync_meta")
for r in c.fetchall():
    print(f"  {r[0]}: {r[1][:50]}")
