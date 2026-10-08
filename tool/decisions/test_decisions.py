"""Tests for decisions.py. Run: python3 -I tool/decisions/test_decisions.py"""

import importlib.util
import pathlib
import shutil
import sys
import tempfile
import unittest

HERE = pathlib.Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("decisions", HERE / "decisions.py")
dec = importlib.util.module_from_spec(spec)
spec.loader.exec_module(dec)


class DecisionLogTest(unittest.TestCase):
    def setUp(self):
        self.tmp = pathlib.Path(tempfile.mkdtemp())
        (self.tmp / "docs" / "decisions").mkdir(parents=True)
        (self.tmp / "docs" / "adr").mkdir(parents=True)
        shutil.copy(dec.DECISIONS / "TEMPLATE.md", self.tmp / "docs" / "decisions" / "TEMPLATE.md")
        (self.tmp / "docs" / "adr" / "0001-cubit.md").write_text(
            "# ADR 0001: Dùng Cubit mặc định\n\n- Trạng thái: Accepted\n- Ngày: 2026-08-26\n\n"
            "## Quyết định\n\nCubit cho đa số màn hình.\n", encoding="utf-8")
        self._saved = (dec.ROOT, dec.DECISIONS, dec.ADR, dec.INDEX)
        dec.ROOT = self.tmp
        dec.DECISIONS = self.tmp / "docs" / "decisions"
        dec.ADR = self.tmp / "docs" / "adr"
        dec.INDEX = dec.DECISIONS / "README.md"

    def tearDown(self):
        dec.ROOT, dec.DECISIONS, dec.ADR, dec.INDEX = self._saved
        shutil.rmtree(self.tmp)

    def run_cli(self, *argv):
        return dec.main(list(argv))

    def test_new_numbers_feature_decisions_and_reads_adrs(self):
        self.run_cli("new", "Phân trang theo trang", "--tags", "pagination,list")
        self.run_cli("new", "Định dạng tiền", "--tags", "money")
        names = sorted(p.name for p in dec.DECISIONS.glob("D-*.md"))
        self.assertEqual(names, ["D-0001-phan-trang-theo-trang.md", "D-0002-dinh-dang-tien.md"])
        loaded = {d.id: d for d in dec.load()}
        self.assertEqual(loaded["D-0001"].status, "proposed")
        self.assertEqual(loaded["D-0001"].tags, ["pagination", "list"])
        self.assertEqual(loaded["ADR-0001"].status, "accepted")
        self.assertEqual(loaded["ADR-0001"].summary, "Cubit cho đa số màn hình.")

    def test_project_scope_creates_the_next_adr(self):
        self.run_cli("new", "Giữ REST", "--scope", "project")
        self.assertTrue((dec.ADR / "0002-giu-rest.md").exists())

    def test_search_ignores_diacritics_and_hides_superseded(self):
        self.run_cli("new", "Phân trang theo trang", "--tags", "pagination")
        path = next(dec.DECISIONS.glob("D-0001-*.md"))
        text = path.read_text(encoding="utf-8").replace("Trạng thái: proposed", "Trạng thái: superseded")
        path.write_text(text, encoding="utf-8")
        ranked = [d.id for d in dec.load() if dec._score(d, ["phan", "trang"])]
        self.assertIn("D-0001", ranked)
        self.assertEqual(dec._fold("Phân trang"), "phan trang")

    def test_check_flags_missing_sections_and_stale_index(self):
        self.run_cli("new", "Cache ảnh", "--tags", "image")
        self.run_cli("index")
        self.assertEqual(dec.problems(dec.load()), [])
        path = next(dec.DECISIONS.glob("D-0001-*.md"))
        path.write_text(path.read_text(encoding="utf-8").replace("## Hệ quả", "## Khác"), encoding="utf-8")
        found = dec.problems(dec.load())
        self.assertTrue(any("thiếu mục '## Hệ quả'" in p for p in found))
        self.run_cli("new", "Quyết định thêm sau khi index", "--tags", "x")
        found = dec.problems(dec.load())
        self.assertTrue(any("README.md đã cũ" in p for p in found))

    def test_superseded_requires_a_valid_replacement(self):
        self.run_cli("new", "A", "--tags", "x")
        path = next(dec.DECISIONS.glob("D-0001-*.md"))
        text = path.read_text(encoding="utf-8").replace("Trạng thái: proposed", "Trạng thái: superseded")
        path.write_text(text, encoding="utf-8")
        self.assertTrue(any("thiếu 'Bị thay bởi:'" in p for p in dec.problems(dec.load())))
        path.write_text(text.replace("- Bị thay bởi:", "- Bị thay bởi: D-0009"), encoding="utf-8")
        self.assertTrue(any("D-0009 không tồn tại" in p for p in dec.problems(dec.load())))

    def test_index_groups_by_status(self):
        self.run_cli("new", "Phân trang", "--tags", "pagination")
        index = dec.build_index(dec.load())
        self.assertIn("## Đang áp dụng", index)
        self.assertIn("[ADR-0001](../adr/0001-cubit.md)", index)
        self.assertIn("## Đang chờ duyệt", index)
        self.assertIn("[D-0001](D-0001-phan-trang.md)", index)


if __name__ == "__main__":
    sys.exit(0 if unittest.main(exit=False).result.wasSuccessful() else 1)
