# doom.consumable:noop - 空函数标签的内置占位
# BUG-5 修复：空 values 的函数标签被 function #tag 调用时，1.21.6 每次都报
# Can't find any functions（软错误不中断但污染日志）。内置 no-op 成员让标签永远合法，
# 第三方 add 的成员照常合并（tag 语义=并集）。
