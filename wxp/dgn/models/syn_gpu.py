from graphics import *
import numpy as np
from mpl_toolkits.mplot3d import Axes3D
import matplotlib.pyplot as plt
import math
import time
import csv


"	Global variables	"
canvas_w	=	640
canvas_h	=	480

"	Function to plot a point on the canvas	"
def	putpxl(x,y,w,color):
	w.plotPixel(x,y,color)


"	Bressenham line drawing algorithm	"
"		Picked up straight from wikipedia	[http://en.wikipedia.org/wiki/Bresenham's_line_algorithm#Simplification]"
def	draw_line(x0,y0,x1,y1,w):
	dx	=	abs(x1-x0)
	dy	=	abs(y1-y0)
	
	if(x0<x1):
		sx	=	1
	else:
		sx	=	-1
	
	if(y0<y1):
		sy	=	1
	else:
		sy	=	-1
	
	err	=	dx-dy

	while(1):
		putpxl(x0,y0,w,color_rgb(0,0,0))

		if(x0==x1):
			if(y0==y1):
				break
		
		e2	=	2*err

		if(e2>-dy):
			err	=	err-dy
			x0	=	x0+sx
		
		if(e2<dx):
			err	=	err+dx
			y0	=	y0+sy
		
	print('Done with line')


def draw_line_anti(x0,y0,x1,y1,w):
	dx	=	abs(x1-x0)
	dy	=	abs(y1-y0)
	
	if(x0<x1):
		sx	=	1
	else:
		sx	=	-1
	
	if(y0<y1):
		sy	=	1
	else:
		sy	=	-1
	
	err	=	dx-dy
	v1  = 2*(dx-dy)
	ddx = dy
	
	while(1):
		e2	=	2*err
		
		if(dx>=dy):
			if(v1>=e2):
				shade1 = 127*((dx - ddx)/dx) 
				putpxl(x0,y0,w,color_rgb(shade1,shade1,shade1))
				shade2 = 255 - shade1
				putpxl(x0,y0+1,w,color_rgb(shade2,shade2,shade2))
			else:
				shade1 = 127*((dx - ddx)/dx) 
				putpxl(x0,y0,w,color_rgb(shade1,shade1,shade1))
				shade2 = 255 - shade1
				putpxl(x0,y0-1,w,color_rgb(shade2,shade2,shade2))
		else:
			if(v1<e2):
				shade1 = 127*((dy - ddx)/dy) 
				putpxl(x0,y0,w,color_rgb(shade1,shade1,shade1))
				shade2 = 255 - shade1
				putpxl(x0+1,y0,w,color_rgb(shade2,shade2,shade2))
			else:
				shade1 = 127*((dy - ddx)/dy) 
				putpxl(x0,y0,w,color_rgb(shade1,shade1,shade1))
				shade2 = 255 - shade1
				putpxl(x0-1,y0,w,color_rgb(shade2,shade2,shade2))
		
		
		if(x0==x1):
			if(y0==y1):
				break
		
		
		if(e2>-dy):
			err	=	err-dy
			x0	=	x0+sx
			ddx = ddx + dy
		
		if(e2<dx):
			err	=	err+dx
			y0	=	y0+sy
			ddx = ddx - dx
		
	print('Done with line')



def	plot_ycbcr_cube():
	fig = plt.figure()
	ax = fig.add_subplot(111, projection='3d')
	
	for y in range (0, 16):
		for cb in range (0, 4):
			for cr in range (0, 4):
				y1 = 16 + (y*14.6)
				cb1= 16 + (cb*74.66667)
				cr1= 16 + (cr*74.66667)
				
				r = (1.164*(y1 - 16) + 1.793*(cr1 - 128))
				g = (1.164*(y1 - 16) - 0.213*(cb1 - 128) - 0.533*(cr - 128))
				b = (1.164*(y1 - 16) + 2.112*(cb1 - 128))
				
				if(r<0):
					r = 0
				elif(r > 255):
					r = 255
				
				if(g<0):
					g = 0
				elif(g > 255):
					g = 255
				
				if(b<0):
					b = 0
				elif(b > 255):
					b = 255
				
				ax.scatter(y,cb,cr, c=color_rgb(r,g,b), marker='o', s=200)
	
	ax.set_xlabel('Y')
	ax.set_ylabel('Cb')
	ax.set_zlabel('Cr')
	
	plt.show()


def plot_hsi_cube():
	pi = 3.142
	fig = plt.figure()
	ax = fig.add_subplot(111, projection='3d')
	file = open("hsi2rgb.txt", "w")
	
	for h in range (0, 8):
		for s in range (0, 4):
			for i in range (0, 8):
				h1 = (h * pi)/4
				s1 = s/4
				i1 = i/8
				
				if(h1 < (2*pi/3)):
					h2 = h1
				elif(h1 < (4*pi/3)):
					h2 = h1 - (2*pi/3)
				elif(h1 < (2*pi)):
					h2 = h1 - (4*pi/3)
				
				x  = i1*(1-s1)
				y  = i1*(1 + (s1*math.cos(h2))/math.cos((pi/3) - h2) )
				z  = 3*i1 - (x + y)
				
				if(h1 < (2*pi/3)):
					r = y
					g = z
					b = x
				elif(h1 < (4*pi/3)):
					r = x
					g = y
					b = z
				elif(h1 < (2*pi)):
					r = z
					g = x
					b = y
				
				r = r * 255
				g = g * 255
				b = b * 255
				
				if(r<0):
					r = 0
				elif(r > 255):
					r = 255
				
				if(g<0):
					g = 0
				elif(g > 255):
					g = 255
				
				if(b<0):
					b = 0
				elif(b > 255):
					b = 255
				
				val= (int(r/16) * 256) + (int(g/16) * 16) + int(b/16);
				
				file.write('h:'+str(h)+' s:'+str(s)+' i:'+str(i)+' -> r:'+str(int(r/16))+' g:'+str(int(g/16))+' b:'+str(int(b/16))+' | val:'+str(int(val))+'\n')
				
				ax.scatter(h,s,i, c=color_rgb(r,g,b), marker='o', s=200)
	
	file.close()
	
	ax.set_xlabel('H')
	ax.set_ylabel('S')
	ax.set_zlabel('I')
	
	plt.show()


def draw_conic(a,b,c,d,e,x0,y0,w):
	num_loops = 0
	out_file = open('draw_conic.csv', 'w', newline='')
	logit = csv.writer(out_file)
	
	logit.writerow(['a','b','c','d','e','x0','y0'])
	logit.writerow([a,b,c,d,e,x0,y0])
	logit.writerow([''])
	logit.writerow(['step_no','quad','k1','k2','n','curv','fx1','fy2','b12','d1','d2','d3','d4','x','y','action'])
	
	def mt1():
		nonlocal a,c,d,e
		tmp = a
		a   = c
		c   = tmp
		
		tmp = d
		d   = e
		e   = tmp
	
	" Find initial quadrant "
	if((d>=0) and (e<0)):
		quad = 1
	elif((d>0) and (e>=0)):
		quad = 2
	elif((d<=0) and (e>0)):
		quad = 3
	else:
		quad = 4
	
	"Find values for k1,k2 & n"
	if(quad <= 2):
		k1 = 1
	else:
		k1 = -1
	
	if((quad == 2) or (quad == 3)):
		k2 = -1
	else:
		k2 = 1
		
	def update_n():
		nonlocal n
		if((quad == 1) or (quad == 3)):
			n = 1
		else:
			n = 0
	
	update_n()
	
	"Calculate curvature C @ (0,0)"
	curv = (a*e*e)+(c*d*d)-(b*e*d)
	
	if(curv > 0):
		curv = 1
	elif(curv < 0):
		curv = -1
		temp = k1
		k1 = k2
		k2 = temp
		n = n ^ 1
		a = (-1)*a
		b = (-1)*b
		c = (-1)*c
		d = (-1)*d
		e = (-1)*e
	else:
		curv = 0
	
	if(n == 0):
		mt1()
	
	fx1 = d*k1
	fy2 = e*k2
	b12 = b*k1*k2
	d1  = math.floor(0.5*d*k1) + math.floor(0.25*a)
	d2  = (d*k1) + math.floor(0.5*e*k2) + a + math.floor(0.25*c) + math.floor(0.5*b)
	d3  = math.floor(0.5*d*k1) + (e*k2) + math.floor(0.25*a) + c + math.floor(0.5*b12)
	d4  = math.floor(-0.5*d*k1) + (e*k2) + math.floor(0.25*a) + c - math.floor(0.5*b12)
	
	logit.writerow([''])
	logit.writerow(['Init Quadrant :',quad])
	logit.writerow(['a','b12','c','d','e','k1','k2'])
	logit.writerow([a,b12,c,d,e,k1,k2])
	logit.writerow([])
	logit.writerow(['step_no','quad','k1','k2','n','curv','fx1','fy2','b12','d1','d2','d3','d4','x','y','action'])
	"End of init"
	
	def t2k():
		nonlocal k1,k2
		tmp = k2
		k2  = -1*k1
		k1  = tmp
	
	def t2g():
		nonlocal fx1,fy2
		tmp = fy2
		fy2 = -1*fx1
		fx1 = tmp
	
	def quad_update():
		nonlocal b12,d1,d2,d3,d4,quad
		mt1()
		t2k()
		t2g()
		b12 = -1*b12
		
		d1 += math.floor(0.5*(fy2 - fx1)) - math.floor(0.25*(a-c))
		d2 += math.floor(0.5*fy2) - math.floor(1.5*fx1) - math.floor(0.75*(a-c)) - b12
		d3 += math.floor(-0.5*fy2) - math.floor(1.5*fx1) + math.floor(0.75*(a-c)) - b12
		d4 += math.floor(-1.5*fy2) - math.floor(0.5*fx1) + math.floor(0.75*(a-c)) + b12
		
		quad = quad + 1
		if(quad == 5):
			quad = 1
		
		update_n()
		
		logit.writerow([''])
		logit.writerow(['Quadrant Update:',quad])
		logit.writerow(['a','b12','c','d','e','k1','k2','','d1','d2','d3','d4'])
		logit.writerow([a,b12,c,d,e,k1,k2,'',d1,d2,d3,d4])
		logit.writerow([])
		logit.writerow(['step_no','quad','k1','k2','n','curv','fx1','fy2','b12','d1','d2','d3','d4','x','y','action'])
	
	def xsqare_move():
		nonlocal b12,d1,d2,d3,d4,a,fx1,fy2
		d1 = d1 + fx1 + 2*a
		d2 = d2 + fx1 + 3*a + 0.5*b12
		d3 = d3 + fx1 + 2*a + b12
		d4 = d4 + fx1 + 2*a
		fx1 = fx1 + 2*a
		fy2 = fy2 + b12
	
	def diag_move():
		nonlocal b12,d1,d2,d3,d4,a,c,fx1,fy2
		d1 = d1 + fx1 + fy2 + 2*a + c + 1.5*b12
		d2 = d2 + fx1 + fy2 + 3*a + 2*c + 4.5*b12
		d3 = d3 + fx1 + fy2 + 2*a + 3*c + 4.5*b12
		d4 = d4 + fx1 + fy2 + 3*c + 1.5*b12
		fx1 = fx1 + 2*a + b12
		fy2 = fy2 + 2*c + b12
	
	def ysquare_move():
		nonlocal b12,d1,d2,d3,d4,c,fx1,fy2
		d1 = d1 + fy2 + c + 0.5*b12
		d2 = d2 + fy2 + 2*c + b12
		d3 = d3 + fy2 + 3*c + 0.5*b12
		d4 = d4 + fy2 + 3*c - 0.5*b12
		fx1 = fx1 + b12
		fy2 = fy2 + 2*c
	
	x = x0
	y = y0
	action = ''
	
	"Main loop"
	while(1):
		if((num_loops % 10) == 0):
			time.sleep(1)
		
		if((d1 <= 0) or (d2 < 0)):
			if(n):
				x += k1
			else:
				y += k1
			
			action = 'xsqare_move'
			logit.writerow([num_loops,quad,k1,k2,n,curv,fx1,fy2,b12,d1,d2,d3,d4,x-x0,y-y0,action])
			putpxl(x,y,w,color_rgb(0,0,0))
			xsqare_move()
			num_loops += 1
			if(((x == x0) and (y == y0)) or (num_loops > 1000)):
				break
		elif(d3 <= 0):
			if(n):
				x += k1
				y += k2
			else:
				y += k1
				x += k2
			
			action = 'diag_move'
			logit.writerow([num_loops,quad,k1,k2,n,curv,fx1,fy2,b12,d1,d2,d3,d4,x-x0,y-y0,action])
			putpxl(x,y,w,color_rgb(0,0,0))
			diag_move()
			num_loops += 1
			if(((x == x0) and (y == y0)) or (num_loops > 1000)):
				break
		elif(d4 <= 0):
			if(n):
				y += k2
			else:
				x += k2
			
			action = 'ysquare_move'
			logit.writerow([num_loops,quad,k1,k2,n,curv,fx1,fy2,b12,d1,d2,d3,d4,x-x0,y-y0,action])
			putpxl(x,y,w,color_rgb(0,0,0))
			ysquare_move()
			num_loops += 1
			if(((x == x0) and (y == y0)) or (num_loops > 1000)):
				break
		else:
			action = 'quad_update'
			logit.writerow([num_loops,quad,k1,k2,n,curv,fx1,fy2,b12,d1,d2,d3,d4,'-','-',action])
			num_loops += 1
			quad_update()
		
	
	del logit
	out_file.close()


def draw_line_bezier(x0,y0,x1,y1,w):
	putpxl((int(x0+x1)/2),(int(y0+y1)/2),w,color_rgb(0,0,0))
	
	if((abs(x0-x1) <= 1) and (abs(y0-y1) <= 1)):
		return
	
	draw_line_bezier(x0,y0,int((x0+x1)/2),int((y0+y1)/2),w)
	draw_line_bezier(int((x0+x1)/2),int((y0+y1)/2),x1,y1,w)

def draw_curve_bezier(x0,y0,x1,y1,x2,y2,w):
	midx1 = int(x0+x1)/2
	midy1 = int(y0+y1)/2
	midx2 = int(x1+x2)/2
	midy2 = int(y1+y2)/2
	midx3 = int(midx1+midx2)/2
	midy3 = int(midy1+midy2)/2
	
	putpxl(midx3,midy3,w,color_rgb(0,0,0))
	"print('putpxl x:'+str(midx3)+' y:'+str(midy3))"
	
	if((abs(midx1 - x0) >= 1) or (abs(midy1 - y0) >= 1)):
		draw_curve_bezier(x0,y0,midx1,midy1,midx3,midy3,w)
	
	if((abs(midx2 - x2) >= 1) or (abs(midy2 - y2) >= 1)):
		draw_curve_bezier(midx3,midy3,midx2,midy2,x2,y2,w)
	


"	Work Area	-	Write code to test models here ..."
#win = GraphWin('syn_canvas ' + str(canvas_w) + 'x' + str(canvas_h),canvas_w,canvas_h)

#pt = Point(200,200)
#pt.draw(win)

"draw_conic(45,52,45,300,384,320,240,win)"

#draw_line_bezier(0,0,600,400,win)
#draw_line(0,50,600,450,win)

#draw_curve_bezier(0,0,100,0,100,50,win)
#draw_curve_bezier(100,50,100,300,200,300,win)
#draw_curve_bezier(200,300,600,300,600,400,win)

"plot_ycbcr_cube()"
plot_hsi_cube()

file = open("test.txt", "w")
file.write("Hello\n")
file.close()


input("waiting ...")
