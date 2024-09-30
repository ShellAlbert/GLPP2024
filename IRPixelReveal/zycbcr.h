#ifndef ZYCBCR_H
#define ZYCBCR_H


#include <QtCore>
class ZYCbCr
{
public:
  ZYCbCr(float Y, float Cb, float Cr);

public:
  float m_Y;
  float m_Cb;
  float m_Cr;

public:
  bool isEqual(ZYCbCr pixel);
};
#endif // ZYCBCR_H
