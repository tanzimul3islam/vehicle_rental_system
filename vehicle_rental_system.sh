#!/bin/bash

# File to store vehicle data
VEHICLE_FILE="vehicles.csv"

# File to store rental records
RENTAL_FILE="rentals.csv"


# Initialize files if they don't exist
if [ ! -f "$VEHICLE_FILE" ]; then
    touch "$VEHICLE_FILE"
    echo "Vehicle file created."
fi

if [ ! -f "$RENTAL_FILE" ]; then
    touch "$RENTAL_FILE"
    echo "Rental file created."
fi


# Function to add a new vehicle
add_vehicle() {
    echo "===================="
    echo " Add a New Vehicle "
    echo "===================="
    read -p "Enter Registration Number: " regNo
    read -p "Enter Vehicle Type (Bus/Minibus/Car): " type
    read -p "Enter Daily Rental Price: " price

    # Check if the vehicle already exists
    if grep -q "^$regNo|" "$VEHICLE_FILE"; then
        echo "Error: A vehicle with this registration number already exists!"
        return
    fi

    # Add the new vehicle to the file
    echo "$regNo    $type   Available   $price" >> "$VEHICLE_FILE"
    echo "Vehicle added successfully!"
}



# Function to update vehicle details
update_vehicle() {
    echo "===================="
    echo " Update Vehicle Details "
    echo "===================="
    read -p "Enter Registration Number of the vehicle to update: " regNo

    # Check if the vehicle exists
    if ! grep -q "^$regNo" "$VEHICLE_FILE"; then
        echo "Error: No vehicle found with this registration number!"
        return
    fi

    echo "What would you like to update?"
    echo "1. Daily Rental Price"
    echo "2. Availability Status"
    read -p "Enter your choice: " update_choice

    case $update_choice in
        1)
            read -p "Enter new daily rental price: " new_price
            declare type
            declare status
            type=$(grep "^$regNo" vehicles.csv | awk '{print $2}')
            status=$(grep "^$regNo" vehicles.csv | awk '{print $3}')
            sed -i "/^$regNo/ s/.*/$regNo    $type   $status   $new_price/" $VEHICLE_FILE

            echo "Vehicle price updated successfully!"
            ;;
        2)
            read -p "Enter new availability status (Available/Unavailable): " new_status
            type=$(grep "^$regNo" vehicles.csv | awk '{print $2}')
            price=$(grep "^$regNo" vehicles.csv | awk '{print $4}')
            sed -i "/^$regNo/ s/.*/$regNo    $type   $new_status   $price/" $VEHICLE_FILE
            echo "Vehicle availability updated successfully!"
            ;;
        *)
            echo "Invalid choice! Returning to the menu."
            ;;
    esac
}

# Function to remove a vehicle
remove_vehicle() {
    echo "===================="
    echo " Remove a Vehicle "
    echo "===================="
    read -p "Enter Registration Number of the vehicle to remove: " regNo

    # Check if the vehicle exists
    if ! grep -q "^$regNo" "$VEHICLE_FILE"; then
        echo "Error: No vehicle found with this registration number!"
        return
    fi

    # Remove the vehicle from the file
    sed -i "/^$regNo/d" "$VEHICLE_FILE"
    echo "Vehicle removed successfully!"
}

View_Rental(){
    cat $VEHICLE_FILE
}


# Function to display available vehicles
display_available_vehicles() {
    echo "===================="
    echo " Available Vehicles "
    echo "===================="
    echo "Registration_Number     Type      Daily_Price"
    grep Available $VEHICLE_FILE | awk '{print "\t" $1 "\t\t" $2 "\t\t" $4}'
}


# Function to rent a vehicle
rent_vehicle() {
    echo "===================="
    echo " Rent a Vehicle "
    echo "===================="

    # Display available vehicles
    display_available_vehicles

    # Prompt user for rental details
    read -p "Enter Registration Number of the vehicle: " regNo
    read -p "Enter your University ID: " userId
    read -p "Enter Rental Duration (days): " rentalDays

    # Check if the vehicle is available
    if grep -q "^$regNo.*Available" "$VEHICLE_FILE"; then
        # Fetch daily rental price
        dailyPrice=$(grep "^$regNo" "$VEHICLE_FILE" | awk '{print $4}')
        # Calculate total rental fee
        totalFee=$((dailyPrice * rentalDays))

        # Update vehicle status to unavailable
        sed -i "s/^$regNo.*Available/$regNo    $(awk '{print $2}' <<< "$(grep "^$regNo" "$VEHICLE_FILE")")    Unavailable/" "$VEHICLE_FILE"

        # Record rental details
        echo "$userId   $regNo  $(date +%Y-%m-%d) $rentalDays $totalFee" >> "$RENTAL_FILE"

        echo "Vehicle rented successfully!"
        echo "Rental Details:"
        echo "University ID: $userId"
        echo "Vehicle: $regNo"
        echo "Rental Duration: $rentalDays days"
        echo "Total Fee: $totalFee"
    else
        echo "Error: Vehicle not available. Please choose another vehicle."
    fi
}


return_vehicle(){
    echo "===================="
    echo " Return a Vehicle "
    echo "===================="

    # Prompt user for return details
    read -p "Enter Registration Number of the vehicle: " regNo
    read -p "Enter your University ID: " userId
    read -p "Enter Return Duration (days): " returnDays

    # Fetch daily rental price
    dailyPrice=$(grep "^$regNo" "$VEHICLE_FILE" | awk '{print $4}')
    # Fetch rental days
    RentalDays=$(grep "^$userId" "$RENTAL_FILE" | awk '{print $4}')

    # Validate inputs
    if [ -z "$dailyPrice" ] || [ -z "$RentalDays" ]; then
        echo "Error: Invalid Registration Number or University ID."
        return
    fi

    if [ $RentalDays -lt $returnDays ]; then
        declare extra_days=$((returnDays - RentalDays))
        price=$((extra_days * dailyPrice))

        echo "You have exceeded the rental duration by $extra_days days."
        echo "Additional charges: $price"
    fi
    
    # Update vehicle status to available
        sed -i "s/^$regNo.*Unavailable/$regNo    $(awk '{print $2}' <<< "$(grep "^$regNo" "$VEHICLE_FILE")")    Available/" "$VEHICLE_FILE"

    echo "Vehicle returned successfully."
        
}





# Function to display the main menu
main_menu() {
    echo "===================="
    echo " Vehicle Rental System "
    echo "===================="
    echo "1. Transport Manager Portal"
    echo "2. Staff/Student Portal"
    echo "3. Exit"
    echo "===================="
    read -p "Enter your choice: " choice

    case $choice in
        1)
            transport_manager_login
            ;;
        2)
            student_menu
            ;;
        3)
            echo "Exiting the system. Goodbye!"
            exit 0
            ;;
        *)
            echo "Invalid choice! Please try again."
            main_menu
            ;;
    esac
}

# Password for Transport Manager Portal
MANAGER_PASSWORD="12345"


# Function for Manager login
transport_manager_login() {
    echo "===================="
    echo " Transport Manager Login "
    echo "===================="
    read -sp "Enter Password: " password
    echo

    if [ "$password" == "$MANAGER_PASSWORD" ]; then
        manager_menu
    else
        echo "Incorrect password! Returning to the main menu."
        main_menu
    fi
}


# Function to display the Transport Manager menu
manager_menu() {
    echo "===================="
    echo " Transport Manager Menu "
    echo "===================="
    echo "1. Add Vehicle"
    echo "2. Update Vehicle"
    echo "3. Remove Vehicle"
    echo "4. View Rental Logs"
    echo "5. Logout"
    echo "===================="
    read -p "Enter your choice: " manager_choice

    case $manager_choice in
        1)
            echo "Add Vehicle Functionality Here"
            add_vehicle
            manager_menu
            ;;
        2)
            echo "Update Vehicle Functionality Here"
            update_vehicle
            manager_menu
            ;;
        3)
            echo "Remove Vehicle Functionality Here"
            remove_vehicle
            manager_menu
            ;;
        4)
            echo "View Rental Logs Functionality Here"
            View_Rental
            manager_menu
            ;;
        5)
            echo "Logging out..."
            main_menu
            ;;
        *)
            echo "Invalid choice! Please try again."
            manager_menu
            ;;
    esac
}


# Function to display the Student menu
student_menu() {
    echo "===================="
    echo " Staff/Student Menu "
    echo "===================="
    echo "1. Check Vehicle Availability"
    echo "2. Rent a Vehicle"
    echo "3. Return a Vehicle"
    echo "4. Go Back to Main Menu"
    echo "===================="
    read -p "Enter your choice: " student_choice

    case $student_choice in
        1)
            echo "Check Vehicle Availability Functionality Here"
            display_available_vehicles
            student_menu
            ;;
        2)
            echo "Rent a Vehicle Functionality Here"
            rent_vehicle
            student_menu
            ;;
        3)
            echo "Return a Vehicle Functionality Here"
            return_vehicle
            student_menu
            ;;
        4)
            main_menu
            ;;
        *)
            echo "Invalid choice! Please try again."
            student_menu
            ;;
    esac
}




while true;

do
   main_menu
done