#ifndef ZRGB_H
#define ZRGB_H

#include <QtCore>
class ZRGB
{
public:
  ZRGB(uint8_t r, uint8_t g, uint8_t b);

public:
  uint8_t m_R;
  uint8_t m_G;
  uint8_t m_B;

public:
  bool isEqual(ZRGB pixel);
};

#endif // ZRGB_H
