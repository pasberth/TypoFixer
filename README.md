
Usage:

    require "typofixer"

    include TypoFixer::TypoTracker

    purs "hello typo"

    # もしかして: puts
    # ... caller ...
    # hello typo # 期待される出力.

---

    self.typoout = nil

    purs "hello typo"

    # hello typo # もしかして: も caller も出力されない

---

    self.typoout = open "typo.out", "a"
    
    purs "hello typo"
    # hello typo # そして typo.out にログが追加書き込みされる
