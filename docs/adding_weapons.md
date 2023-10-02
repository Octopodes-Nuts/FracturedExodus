# Adding Weapons

The following document shows the process to add guns to the project. This involves minimal coding -- just a few lines for registration -- and weapon sighting.

## 1. Creating the weapon folder and scene.

Your new gun will go in the following directory:

res://behavior/player/weapons/guns/your_gun_name.

Create this folder and then right click the folder and press 'add new scene'. This will bring up a blank scene in Godot. In the top left select 'other nodes' and navigate to static body. This is just a decision that was made, it may change in the future, but right now, weapons are static bodies. Name this static body your_gun_name Once you have this new scene, add the mesh for your gun as well as a collision shape for the static body. Disable the collision shape.

## 2. Creating the script for your gun

Your gun needs a script and creating this script it very easy. Right click your folder again and choose 'new script' and name it YourGunName. This script will contain only a few lines of code. You will set the sounds of your weapon -- currently the only one is fire_sound, and the faction your gun belongs to.

Delete all of the code that auto generates and use the following template:

```
extends Gun

func _init():
    faction = Factions.FACTION

func _ready():
    fire_sound = preload('path/to/weapon/fire/sound.mps')
```

After this script is created, drag your script onto the static body created in the last step and, once that static body is selected, all parameters that pertain to your weapon can be edited in the inspector.

## 3. Registering your weapon

Your weapon can be registered in the weapon_register.gd script. Simply add a new elecment to the dictionary for the type of weapon you have added in the following format:
```
"YourGunName": load("path/to/your/gun/scene.tscn")
```
Congratulations! Your gun has been registered.

## 4. Staging

Right now staging is done in the staging scene. You will have to change the default scene in the project settings to show this staging scene, but use this scene to find which positions work best for your gun and add those to the Default position and Ads position fields in the inspector in your gun scene. Reach out to me (Isaiah) on discord if you have any questions on this workflow and update this document as necessary.