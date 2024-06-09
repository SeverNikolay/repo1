#!/usr/bin/env python3

import xml.etree.ElementTree as ET

graph = []   # граф связей машин между собой
vms = {}     # вспомогательный словарь сопоставлений id машин и их имён

# вспомогательный словарь соспоставлений шейпов и типов машин
vmtypes = {
             'mxgraph.cisco19.rect': 'router',
             'mxgraph.cisco19.workstation': 'workstation',
             'mxgraph.cisco19.server': 'server',
             'cloud': 'internet',
          }

vmtp = [] #Сопоставление устройств и их типов

tree = ET.parse('DE1.drawio')
root = tree.getroot()[0][0][0]

# формируем словарь vms
for cell in root:
    style = cell.attrib.get('style')
    value = cell.attrib.get('value')
    ident = cell.attrib.get('id')
    if isinstance(style, str):
        part = style.partition('shape=')
        if part[1] != '':
            vms[ident] = value
            print(part[2].partition(';')[0])
            
            #Сопоставление устройств и их типов, запись в файл
            vmtp.append((vms[ident], vmtypes[part[2].partition(';')[0]]))
            print (vmtp)
            with open ('fileType.txt', 'w') as file:
                for item in vmtp:
                    dataStr=' : '.join(item)
                    file.write(dataStr + '\n')
        
        


# строим граф
for cell in root.findall('mxCell'):
    for geometry in cell.findall('mxGeometry'):
        for point in geometry.findall('mxPoint'):
            if point.attrib.get('as') == 'sourcePoint':
                graph.append((vms[cell.attrib.get('source')], vms[cell.attrib.get('target')]))
                break


#Запись данный в файл 
with open ('fileGraph.txt', 'w') as file:
    for item in graph:
        dataStr=' : '.join(item)
        print(dataStr)
        file.write(dataStr + '\n')


#Сопоставление устройств и их типов
                             
# TODO сделать вывод в файл 
