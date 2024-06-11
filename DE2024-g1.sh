#!/bin/bash 

# глобальные константы
path="/etc/network/interfaces"
nbr=5 # количество мостов на этом стенде

function deploy_bridges {

    for (( br=101; br <= $((100 + $nst * $nbr)); br++ ))
    do
        echo >> $path
        echo "auto vmbr$br" >> $path
        echo "iface vmbr$br inet manual" >> $path
        echo "	bridge-ports none" >> $path
        echo "	bridge-stp off" >> $path
        echo "	bridge-fd 0" >> $path 
        echo >> $path
        echo "Мост vmbr$br создан";
    done
    
    sleep 1
    systemctl restart networking

}

function deploy_stand {

    # Развертывание HQ-SRV
    br=vmbr$((100 + $nbr * $i + 1))
    nvm=$((500 + 10 * $i)) # номер машины
    qm create $nvm --name "HQ-SRV" --pool "pool-416-g1-node1-$i" --cores 2 --memory 3072 --ostype l26 --scsihw virtio-scsi-single --net0 e1000,bridge=$br,firewall=1 --vga qxl
    if [ $? -ne 0 ]; then echo "Ошибка создания HQ-SRV для стенда №$i"; exit 2; fi
    sleep 1
    qm importdisk $nvm /mnt/pve/BACKUP/qcow2/DE2024/SRV.qcow2 STORAGE --format qcow2
    if [ $? -ne 0 ]; then echo "Ошибка импорта диска для HQ-SRV на стенде №$i"; exit 3; fi
    sleep 1
    qm set $nvm -ide0 STORAGE:$nvm/vm-$nvm-disk-0.qcow2 --boot order=ide0
    echo "$nvm" >> .temp_stand_416_g1_$i # вносим информацию о ВМ в файл
    echo; echo "ВМ $vm с номером $nvm на стенде №$i развернута"; echo

    
    # Развертывание HQ-R
    br1=vmbr$((100 + $nbr * $i + 1))
    br2=vmbr$((100 + $nbr * $i + 2))
    nvm=$((501 + 10 * $i)) # номер машины
    qm create $nvm --name "HQ-R" --pool "pool-416-g1-node1-$i" --cores 2 --memory 2048 --ostype l26 --scsihw virtio-scsi-single --net0 e1000,bridge=$br1,firewall=1 --net1 e1000,bridge=$br2,firewall=1 --vga qxl
    if [ $? -ne 0 ]; then echo "Ошибка создания HQ-R для стенда №$i"; exit 2; fi
    sleep 1
    qm importdisk $nvm /mnt/pve/BACKUP/qcow2/DE2024/RTR.qcow2 STORAGE --format qcow2
    if [ $? -ne 0 ]; then echo "Ошибка импорта диска для HQ-R на стенде №$i"; exit 3; fi
    sleep 1
    qm set $nvm -ide0 STORAGE:$nvm/vm-$nvm-disk-0.qcow2 --boot order=ide0
    echo "$nvm" >> .temp_stand_416_g1_$i # вносим информацию о ВМ в файл
    echo; echo "ВМ $vm с номером $nvm на стенде №$i развернута"; echo

    # Развертывание ISP
    lbr=vmbr$((100 + $nbr * $i + 2))
    rbr=vmbr$((100 + $nbr * $i + 3))
    ubr=vmbr$((100 + $nbr * $i + 4))
    nvm=$((502 + 10 * $i)) # номер машины
    qm create $nvm --name "ISP" --pool "pool-416-g1-node1-$i" --cores 2 --memory 2048 --ostype l26 --scsihw virtio-scsi-single --net0 e1000,bridge=$lbr,firewall=1 --net1 e1000,bridge=$rbr,firewall=1 --net2 e1000,bridge=$ubr,firewall=1 --net3 e1000,bridge=vmbr0,firewall=1 --vga qxl
    if [ $? -ne 0 ]; then echo "Ошибка создания ISP для стенда №$i"; exit 2; fi
    sleep 1
    qm importdisk $nvm /mnt/pve/BACKUP/qcow2/DE2024/RTR.qcow2 STORAGE --format qcow2
    if [ $? -ne 0 ]; then echo "Ошибка импорта диска для ISP на стенде №$i"; exit 3; fi
    sleep 1
    qm set $nvm -ide0 STORAGE:$nvm/vm-$nvm-disk-0.qcow2 --boot order=ide0
    echo "$nvm" >> .temp_stand_416_g1_$i # вносим информацию о ВМ в файл
    echo; echo "ВМ $vm с номером $nvm на стенде №$i развернута"; echo

    # Развертывание BR-R
    br1=vmbr$((100 + $nbr * $i + 3))
    br2=vmbr$((100 + $nbr * $i + 5))
    nvm=$((503 + 10 * $i)) # номер машины
    qm create $nvm --name "BR-R" --pool "pool-416-g1-node1-$i" --cores 2 --memory 2048 --ostype l26 --scsihw virtio-scsi-single --net0 e1000,bridge=$br1,firewall=1 --net1 e1000,bridge=$br2,firewall=1 --vga qxl
    if [ $? -ne 0 ]; then echo "Ошибка создания BR-R для стенда №$i"; exit 2; fi
    sleep 1
    qm importdisk $nvm /mnt/pve/BACKUP/qcow2/DE2024/RTR.qcow2 STORAGE --format qcow2
    if [ $? -ne 0 ]; then echo "Ошибка импорта диска для BR-R на стенде №$i"; exit 3; fi
    sleep 1
    qm set $nvm -ide0 STORAGE:$nvm/vm-$nvm-disk-0.qcow2 --boot order=ide0
    echo "$nvm" >> .temp_stand_416_g1_$i # вносим информацию о ВМ в файл
    echo; echo "ВМ $vm с номером $nvm на стенде №$i развернута"; echo

    # Развертывание BR-SRV
    br=vmbr$((100 + $nbr * $i + 5))
    nvm=$((504 + 10 * $i)) # номер машины
    qm create $nvm --name "BR-SRV" --pool "pool-416-g1-node1-$i" --cores 2 --memory 3072 --ostype l26 --scsihw virtio-scsi-single --net0 e1000,bridge=$br,firewall=1 --vga qxl
    if [ $? -ne 0 ]; then echo "Ошибка создания BR-SRV для стенда №$i"; exit 2; fi
    sleep 1
    qm importdisk $nvm /mnt/pve/BACKUP/qcow2/DE2024/SRV.qcow2 STORAGE --format qcow2
    if [ $? -ne 0 ]; then echo "Ошибка импорта диска для BR-SRV на стенде №$i"; exit 3; fi
    sleep 1
    qm importdisk $nvm /mnt/pve/BACKUP/qcow2/DE2024/SRV-disk1.qcow2 STORAGE --format qcow2
    if [ $? -ne 0 ]; then echo "Ошибка импорта первого доп. диска для BR-SRV на стенде №$i"; exit 3; fi
    sleep 1
    qm importdisk $nvm /mnt/pve/BACKUP/qcow2/DE2024/SRV-disk2.qcow2 STORAGE --format qcow2
    if [ $? -ne 0 ]; then echo "Ошибка импорта второго доп. диска для BR-SRV на стенде №$i"; exit 3; fi
    sleep 1
    qm importdisk $nvm /mnt/pve/BACKUP/qcow2/DE2024/SRV-disk3.qcow2 STORAGE --format qcow2
    if [ $? -ne 0 ]; then echo "Ошибка импорта третьего доп. диска для BR-SRV на стенде №$i"; exit 3; fi
    sleep 1
    qm set $nvm -ide0 STORAGE:$nvm/vm-$nvm-disk-0.qcow2 --boot order=ide0
    qm set $nvm -ide1 STORAGE:$nvm/vm-$nvm-disk-1.qcow2
    qm set $nvm -ide2 STORAGE:$nvm/vm-$nvm-disk-2.qcow2
    qm set $nvm -ide2 STORAGE:$nvm/vm-$nvm-disk-3.qcow2
    echo "$nvm" >> .temp_stand_416_g1_$i # вносим информацию о ВМ в файл
    echo; echo "ВМ $vm с номером $nvm на стенде №$i развернута"; echo

    # Развертывание CLI
    br=vmbr$((100 + $nbr * $i + 4))
    nvm=$((505 + 10 * $i)) # номер машины
    qm create $nvm --name "CLI" --pool "pool-416-g1-node1-$i" --cores 1 --memory 2048 --ostype l26 --scsihw virtio-scsi-single --net0 e1000,bridge=$br,firewall=1 --vga qxl
    if [ $? -ne 0 ]; then echo "Ошибка создания CLI для стенда №$i"; exit 2; fi
    sleep 1
    qm importdisk $nvm /mnt/pve/BACKUP/qcow2/DE2024/CLI.qcow2 STORAGE --format qcow2
    if [ $? -ne 0 ]; then echo "Ошибка импорта диска для CLI на стенде №$i"; exit 3; fi
    sleep 1
    qm set $nvm -ide0 STORAGE:$nvm/vm-$nvm-disk-0.qcow2 --boot order=ide0
    echo "$nvm" >> .temp_stand_416_g1_$i # вносим информацию о ВМ в файл
    echo; echo "ВМ $vm с номером $nvm на стенде №$i развернута"; echo
}

function deploy_stands {

    for (( i=0; i < $nst; i++ ))
    do
        pvesh create /pools --poolid "pool-416-g1-node1-$i" # создаём пул
        deploy_stand
    done
}

function delete {
    read -p "Укажите номер удаляемого стенда (нумеруются с нуля): " numst
    max=$(($nbr * $numst))
    for (( j=$((100 + $max + 1)); j <= $((100 + $max + $nbr)); j++ ))
    do
        sed -i "/auto vmbr$j/,+6d" $path                
    done
    sleep 1
    systemctl restart networking
    
    # удаляем ВМ на этом стенде
    while read vm;
    do
        qm stop $vm
        sleep 1
        qm destroy $vm
        sleep 1
        echo "ВМ $vm удалена"
    done < .temp_stand_416_g1_$numst

    rm .temp_stand_416_g1_$numst # удаляем временный файл с номерами ВМ на текущем стенде
    pvesh delete /pools/pool-416-g1-node1-$numst # удаляем пул
    echo "Удалили стенд $numst"
}

function run_stand {
    for n in {0..9}
    do
        VM=$((200 + $n + 10 * $i))
        qm start $VM
        if [ $? -ne 0 ]; then echo "Не могу запустить ВМ с номером $VM на стенде №$i"; exit 4; fi
        echo "ВМ с номером $VM на стенде №$i запущена"
        sleep 2
    done
}

function run_stands {

    for (( i=0; i < $nst; i++ ))
    do
        run_stand
    done

}

clear
echo "+=== Сделай выбор ===+"
echo "|Развернуть стенд: 1 |"
echo "|Удалить стенд: 2    |"
echo "+--------------------+"
read -p  "Выбор: " choice
read -p "Кол-во стендов на этой ноде: " nst

case $choice in
    1)
        deploy_bridges
        deploy_stands
        #run_stands
    ;;
    2)
        delete
    ;;
    *)
        echo "Нереализуемый выбор"
        exit 1
    ;;
esac
