#ifndef ZDIALOGPALETTE_H
#define ZDIALOGPALETTE_H

#include <QObject>
#include <QWidget>
#include <QDialog>
#include <QPaintEvent>
class ZDialogPalette : public QDialog
{
public:
  ZDialogPalette();

protected:
  void paintEvent(QPaintEvent *e);
};

#endif // ZDIALOGPALETTE_H
