terraform {
  backend "azurerm" {
    resource_group_name  = "iacqaautomation-infra"
    storage_account_name = "iacqaautomationtstate"
    container_name       = "tstate"
    key                  = "0seHMQKA6FPH3uH4HhHXeF8x7XyIYTU8uygyV9uS8KSPIA7UFVKPoGPktNGV0KfYvLHS7tgcnrUt+AStngpq1w=="
  }
 
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "0.12.11"
    }
  }
}
provider "azurerm" {
  skip_provider_registration = true 
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}
data "azurerm_client_config" "current" {}
# Create our Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "iacqaautomation-app01"
  location = "US East"
}
# Create our Virtual Network - Jonnychipz-VNET
resource "azurerm_virtual_network" "vnet" {
  name                = "iacqaautomationvnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
# Create our Subnet to hold our VM - Virtual Machines
resource "azurerm_subnet" "sn" {
  name                 = "VM"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}
# Create our Azure Storage Account - 
resource "azurerm_storage_account" "iacqaautomationsa" {
  name                     = "iacqaautomationsa"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags = {
    environment = "jonnychipzenv1"
  }
}
# Create our vNIC for our VM and assign it to our Virtual Machines Subnet
resource "azurerm_network_interface" "vmnic" {
  name                = "iacqaautomationvm01nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.sn.id
    private_ip_address_allocation = "Dynamic"
  }
}
# Create our Virtual Machine
resource "azurerm_virtual_machine" "iacqaautomationvm01" {
  name                  = "iacqaautomationvm01"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.vmnic.id]
  vm_size               = "Standard_B2s"
  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter-Server-Core-smalldisk"
    version   = "latest"
  }
  storage_os_disk {
    name              = "iacqaautomationvm01os"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "iacqaautomationvm01"
    admin_username = "iacqauser"
    admin_password = "Password123$"
  }

  os_profile_windows_config {
  }
}
