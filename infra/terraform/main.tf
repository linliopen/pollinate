resource "azurerm_resource_group" "resourcegroup" {
  name     = var.rg_name
  location = "West US 2"
}

resource "azurerm_virtual_network" "vn" {
  name                = "acctvn"
  address_space       = var.virtual_network_address
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "acctsub"
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  virtual_network_name = azurerm_virtual_network.vn.name
  address_prefix       = var.subnet_address
}

resource "azurerm_public_ip" "pub_ip" {
  name                         = "publicIPForLB"
  location                     = azurerm_resource_group.resourcegroup.location
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  allocation_method            = "Static"
}

resource "azurerm_lb" "lb" {
  name                = "loadBalancer"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  frontend_ip_configuration {
    name                 = "publicIPAddress"
    public_ip_address_id = azurerm_public_ip.pub_ip.id
  }
}

resource "azurerm_lb_backend_address_pool" "address_pool" {
  resource_group_name = azurerm_resource_group.resourcegroup.name
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "BackEndAddressPool"
}

resource "azurerm_network_interface" "network_interface" {
  count               = 2
  name                = "acctni${count.index}"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  ip_configuration {
    name                          = "testConfiguration"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "dynamic"
  }
}

resource "azurerm_managed_disk" "disk" {
  count                = 2
  name                 = "datadisk_existing_${count.index}"
  location             = azurerm_resource_group.resourcegroup.location
  resource_group_name  = azurerm_resource_group.resourcegroup.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "1023"
}

resource "azurerm_availability_set" "avset" {
  name                         = "avset"
  location                     = azurerm_resource_group.resourcegroup.location
  resource_group_name          = azurerm_resource_group.resourcegroup.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2
  managed                      = true
}
// one mysql server
resource "azurerm_mysql_server" "mysql" {
  name                = "mysqlserver"
  location            = azurerm_resource_group.resourcegroup.location
  resource_group_name = azurerm_resource_group.resourcegroup.name

  administrator_login          = "mysqladminun"
  administrator_login_password = "H@Sh1CoR3!"

  sku_name   = "B_Gen5_2"
  storage_mb = 5120
  version    = "5.7"

  auto_grow_enabled                 = true
  backup_retention_days             = 7
  geo_redundant_backup_enabled      = false
  infrastructure_encryption_enabled = false
  public_network_access_enabled     = true
  ssl_enforcement_enabled           = true
  ssl_minimal_tls_version_enforced  = "TLS1_2"
}

// one vm
resource "azurerm_virtual_machine" "vm" {
  count                 = var.count
  name                  = "acctvm${count.index}"
  location              = azurerm_resource_group.resourcegroup.location
  availability_set_id   = azurerm_availability_set.avset.id
  resource_group_name   = azurerm_resource_group.resourcegroup.name
  network_interface_ids = [element(azurerm_network_interface.network_interface.*.id, count.index)]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  # Optional data disks
  storage_data_disk {
    name              = "datadisk_new_${count.index}"
    managed_disk_type = "Standard_LRS"
    create_option     = "Empty"
    lun               = 0
    disk_size_gb      = "1023"
  }

  storage_data_disk {
    name            = element(azurerm_managed_disk.disk.*.name, count.index)
    managed_disk_id = element(azurerm_managed_disk.disk.*.id, count.index)
    create_option   = "Attach"
    lun             = 1
    disk_size_gb    = element(azurerm_managed_disk.disk.*.disk_size_gb, count.index)
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "${var.user}"
    admin_password = "${var.pass}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "${var.env}"
  }
  labels = {
    ansible-group = floor(count.index / var.count ),
    ansible-index = count.index % var.count,
  }
}


data "template_file" "inventory" {
  template = "${file("./inventory.tpl")}"

  vars {
    private_ip      = "${element(azurerm_network_interface.network_interface.*.private_ip_address, count.index)}"
    pub_ip          = "${element(azurerm_public_ip.pub_ip.*.ip_address, count.index)}"
    pass = "${var.pass}"
    user = "${var.user}"
  }
}

resource "local_file" "save_inventory" {
  content  = "${data.template_file.inventory.rendered}"
  filename = "./inventory"
}