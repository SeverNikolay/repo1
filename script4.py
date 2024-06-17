#!/usr/bin/env python3

import xml.etree.ElementTree as ET

graph = []   # граф связей машин между собой
vms = {}     # вспомогательный словарь сопоставлений id машин и их имён

# вспомогательный словарь соспоставлений шейпов и типов машин
vmtypes = {
             'mxgraph.cisco.routers': 'router',
             'mxgraph.cisco.servers': 'server',
             'mxgraph.cisco.switches': 'switch',
             'mxgraph.cisco.computers_and_peripherals' : 'workstation',
             'cloud': 'internet'
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
        #print (part[2])
        if part[1] != '':
            vms[ident] = value
            part=(part[2].partition(';')[0].split('.'))
            part=('.'.join(part[:3]))
            print(part)
            
            #Сопоставление устройств и их типов, запись в файл
            vmtp.append((vms[ident], vmtypes[part]))
            #with open ('fileType.txt', 'w') as file:
            #    for item in vmtp:
            #        dataStr=' : '.join(item)
            #        file.write(dataStr + '\n')

# строим граф
for cell in root.findall('mxCell'):
    for geometry in cell.findall('mxGeometry'):
        for point in geometry.findall('mxPoint'):
            if point.attrib.get('as') == 'sourcePoint':
                graph.append((vms[cell.attrib.get('source')], vms[cell.attrib.get('target')]))
                break

#Запись данный в файл 
#with open ('fileGraph.txt', 'w') as file:
#    for item in graph:
#        dataStr=' : '.join(item)
#        print(dataStr)
#        file.write(dataStr + '\n')

print(graph, '\n')
print(vmtp)

# nbr - это количество мостов на одном стенде без учета моста vmbr0 в WAN
counter = 0
for link in graph:
    if link[0] == 'WAN' or link[1] == 'WAN':
        counter += 1
nbr = len(graph) - counter

# взаимодействие с пользователем
nst = int(input("Введите требуемое количество стендов: "))
nn  = 3                             # количество нод
q, r = nst // nn, nst % nn
L = [[q, 0] for i in range(0, nn)]  # распределение стендов по нодам

# вычисляем, сколько стендов приходится на каждую ноду
for i in range(0, r):
    L[i][0] += 1

# вычисляем, сколько мостов приходится на каждую ноду
for i in L:
    i[1] = nbr * i[0]

# код для создания bash-скрипта, запускающего развёртывание стендов на i-й ноде
for i in range(0, nn):
    with open ('run' + str(i) + '.sh', 'w') as f:
        f.write('#!/bin/bash' + '\n')
        f.write('path="/etc/network/interfaces"' + '\n')
        f.write('nbr=' + str(nbr) + '\n')
        f.write('function deploy_bridges {')
        f.write('for (( br=101; br <= $((100 + ' + str(L[i][1]) + ')); br++ ))' + '\n')
        f.write('do' + '\n')
        f.write('echo >> $path' + '\n')
        f.write('echo "auto vmbr$br" >> $path' + '\n')
        f.write('echo "iface vmbr$br" inet manual >> $path' + '\n')
        f.write('echo "bridge-ports none" >> $path' + '\n')
        f.write('echo "bridge-stp off" >> $path' + '\n')
        f.write('echo "bridge-fd 0" >> $path' + '\n')
        f.write('echo >> $path' + '\n')
        f.write('echo "bridge vmbr$br created";' + '\n')
        f.write('done' + '\n')
        f.write('sleep 1' + '\n')
        f.write('systemctl restart networking' + '\n')
        f.write('}' + '\n')
        
        
        
        f.write('function deploy_stands {' + '\n')
        f.write('for (( i=0; i < $nst; i++ ))' + '\n')
        f.write('do' + '\n')
        f.write('pvesh create /pools --poolid "pool-416-g1-node1-$i"' + '\n')
        f.write('deploy_stand' + '\n')
        f.write('done' + '\n')
        f.write('}' + '\n')
        
        f.write('function delete {' + '\n')
        f.write('read -p "Укажите номер удаляемого стенда (нумеруются с нуля): " numst' + '\n')
        f.write('max=$(($nbr * $numst))' + '\n')
        f.write('for (( j=$((100 + $max + 1)); j <= $((100 + $max + $nbr)); j++ ))' + '\n')
        f.write('do' + '\n')
        f.write('sed -i "/auto vmbr$j/,+6d" $path' + '\n')
        f.write('done' + '\n')
        f.write('sleep 1' + '\n')
        f.write('systemctl restart networking' + '\n')
        # удаляем ВМ на этом стенде
        f.write('while read vm;' + '\n')
        f.write('do' + '\n')
        f.write('qm stop $vm' + '\n')
        f.write('sleep 1' + '\n')
        f.write('qm destroy $vm' + '\n')
        f.write(' sleep 1' + '\n')
        f.write('echo "ВМ $vm удалена"' + '\n')
        f.write('done < .temp_stand_416_g1_$numst' + '\n')
        f.write('rm .temp_stand_416_g1_$numst' + '\n')
        f.write('pvesh delete /pools/pool-416-g1-node1-$numst' + '\n')
        f.write('echo "Удалили стенд $numst"' + '\n')
        f.write('}' + '\n')
        
        f.write('function run_stand {' + '\n')
        f.write('for n in {0..9}' + '\n')
        f.write('do' + '\n')
        f.write('VM=$((200 + $n + 10 * $i))' + '\n')
        f.write('qm start $VM' + '\n')
        f.write('if [ $? -ne 0 ]; then echo "Не могу запустить ВМ с номером $VM на стенде №$i"; exit 4; fi' + '\n')
        f.write('echo "ВМ с номером $VM на стенде №$i запущена"' + '\n')
        f.write('sleep 2' + '\n')
        f.write(' done' + '\n')
        f.write('}' + '\n')
        
        f.write('function run_stands {' + '\n')
        f.write('for (( i=0; i < $nst; i++ ))' + '\n')
        f.write('do' + '\n')
        f.write('run_stand' + '\n')
        f.write('done' + '\n')
        f.write('}' + '\n')
        
        f.write('clear' + '\n')
        f.write('echo "+=== Сделай выбор ===+"' + '\n')
        f.write('echo "|Развернуть стенд: 1 |"' + '\n')
        f.write('echo "|Удалить стенд: 2    |"' + '\n')
        f.write('echo "+--------------------+"' + '\n')
        f.write('read -p  "Выбор: " choice' + '\n')
        f.write('read -p "Кол-во стендов на этой ноде: " nst' + '\n')
        f.write('case $choice in' + '\n')
        f.write('1)' + '\n')
        f.write('deploy_bridges' + '\n')
        f.write('deploy_stands' + '\n')
        f.write('#run_stands' + '\n')
        f.write(';;' + '\n')
        f.write('2)' + '\n')
        f.write('delete' + '\n')
        f.write(';;' + '\n')
        f.write('*)' + '\n')
        f.write('echo "Нереализуемый выбор"' + '\n')
        f.write('exit 1' + '\n')
        f.write(';;' + '\n')
        f.write('esac' + '\n')
        f.write('' + '\n')
        f.write('' + '\n')
        f.write('' + '\n')
        f.write('' + '\n')
        f.write('' + '\n')
        f.write('' + '\n')
        f.write('' + '\n')
        f.write('' + '\n')
        f.write('' + '\n')
        f.write('' + '\n')
        f.write('' + '\n')
        
    
