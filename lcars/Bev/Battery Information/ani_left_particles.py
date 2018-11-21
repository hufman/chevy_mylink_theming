#!/usr/bin/env python3

# pip install svg.path
from svg.path import parse_path
from collections import namedtuple
import itertools
import random
import re
import xml.etree.ElementTree as ET

# load the SVG
ns = {
	'svg': "http://www.w3.org/2000/svg",
	'xlink': "http://www.w3.org/1999/xlink"
}
ET.register_namespace('svg', ns['svg'])
ET.register_namespace('xlink', ns['xlink'])
tree = ET.parse('ani_left.svg')
root = tree.getroot()

layers = list(root)
new_layers = [l for l in layers if re.match('^New.*reverse_left_[0-9]', l.attrib['id'])]
new_layers = list(reversed(new_layers))
particle_layer = root.find("./svg:g[@id='Particles']", ns)
particle_frames = list(particle_layer)

def get_particle_bounding_box(particle):
	if particle.tag == '{http://www.w3.org/2000/svg}path':
		commands = particle.attrib['d']
		steps = parse_path(commands)
		points = []
		for step in steps:
			if hasattr(step, 'start'):
				points.append(step.start)
			if hasattr(step, 'end'):
				points.append(step.end)
		min_x = min((p.real for p in points))
		min_y = min((p.imag for p in points))
		max_x = min((p.real for p in points))
		max_y = min((p.imag for p in points))
		# simple offset
		if hasattr(particle, 'x'):
			min_x += float(particle['x'])
			min_y += float(particle['y'])
			max_x += float(particle['x'])
			max_y += float(particle['y'])
	else:  # rect
		min_x = float(particle.attrib['x'])
		min_y = float(particle.attrib['y'])
		max_x = min_x + float(particle.attrib['width'])
		max_y = min_y + float(particle.attrib['height'])

	# finished the bounding box
	Box = namedtuple('Box', ['left', 'top', 'right', 'bottom'])
	return Box(min_x, min_y, max_x, max_y)
	
y_range = range(128-10, 128+10)
random.seed(0)  # preseed with a constant number
active_particles = []

def add_particle(frame, particle_info):
	particle_frame = particle_frames[particle_info['frame']]
	bounding_box = get_particle_bounding_box(particle_frame)
	middle_box_x = (bounding_box.left + bounding_box.right) / 2
	middle_box_y = (bounding_box.top + bounding_box.bottom) / 2
	offset_x = int(particle_info['x']) - middle_box_x	# add to the x
	offset_y = int(particle_info['y']) - middle_box_y	# add to the x
	
	obj = ET.SubElement(frame, '{http://www.w3.org/2000/svg}use', {
		'{http://www.w3.org/1999/xlink}href': '#%s' % (particle_frame.attrib['id'],),
		'x': str(offset_x),
		'y': str(offset_y),
	})

# clear out old particles
for frame in new_layers:
	for particle in frame:
		if particle.attrib['{http://www.w3.org/1999/xlink}href'].startswith('particle'):
			frame.remove(particle)

# start adding new particles
for frame in new_layers:
	# create the new particle
	particle_info = {
		'frame': random.randint(0, 2),
		'x': random.uniform(214, 220),
		'y': random.uniform(134-6, 134+6),
		'speed_x': random.uniform(-5, -7),
		'speed_y': random.uniform(-10, 10),
	}
	active_particles.append(particle_info)

	for particle_info in list(active_particles):
		add_particle(frame, particle_info)

		# update this particle
		particle_info['speed_x'] *= 1.1
		particle_info['speed_y'] *= 1.1 + ((220 - particle_info['x'])/200)
		particle_info['x'] += particle_info['speed_x']
		particle_info['y'] += particle_info['speed_y']
		particle_info['frame'] += 1
		if particle_info['frame'] >= len(particle_frames):
			particle_info['frame'] = 0
		# expire this particle
		if particle_info['y'] < 50 or \
		   particle_info['y'] > 200 or \
		   particle_info['x'] < 100:
			active_particles.remove(particle_info)

for frame in itertools.cycle(new_layers):
	# run through all the particles to finish looping
	# but don't create any new particles or erase the previous ones
	for particle_info in list(active_particles):
		add_particle(frame, particle_info)

		# update this particle
		particle_info['speed_x'] *= 1.1
		particle_info['speed_y'] *= 1.1 + ((220 - particle_info['x'])/200)
		particle_info['x'] += particle_info['speed_x']
		particle_info['y'] += particle_info['speed_y']
		particle_info['frame'] += 1
		if particle_info['frame'] >= len(particle_frames):
			particle_info['frame'] = 0
		# expire this particle
		if particle_info['y'] < 50 or \
		   particle_info['y'] > 200 or \
		   particle_info['x'] < 100:
			active_particles.remove(particle_info)
	# keep repeating until all the particles are burned out
	if len(active_particles) == 0: break

tree.write('ani_left_new.svg')
