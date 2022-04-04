import '../vim-loader/vim.dart';

mixin Store {
  final Map<int, Vim?> _vims = <int, Vim?>{};

  int get vimCount => _vims.length;

  Vim? getVim([int index = 0]) {
    return _vims[index];
  }

  void addVim(Vim vim) {
    final id = _vims.length;
    _vims[id] = vim..index = id;
  }

  void removeVim(Vim vim) {
    _vims.remove(vim.index);
    //_vims[vim.index.toInt()] = null;
    vim.index = -1;
  }

  bool containsVim(Vim vim) {
    return _vims.values.contains(vim);
  }
}
