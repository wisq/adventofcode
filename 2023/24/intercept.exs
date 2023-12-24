xA = 19
vxA = -2
yA = 13
vyA = 1

xB = 20
vxB = 1
yB = 19
vyB = -5

mA = vyA / vxA
mB = vyB / vxB

# line formula:
#   y = mA*x + (yA - mA*xA)
# rewrite to
#   0 = mA*x - 1*y + (yA - mA*xA)
# terms:
a1 = mA
b1 = 1
c1 = yA - mA * xA
# same for B
a2 = mB
b2 = 1
c2 = yB - mB * xB

x0 = (b1 * c2 - b2 * c1) / (a1 * b2 - a2 * b1)
y0 = (c1 * a2 - c2 * a1) / (a1 * b2 - a2 * b1)

IO.inspect({x0, y0})
