*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser    
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.core.notebook
Library           OperatingSystem
Library           RPA.PDF
Library           RPA.Archive
Library           RPA.Robocloud.Secrets

*** Keywords ***
Open the robot order website
    ${url}=    Get Secret    website
    Open Available Browser      ${url}[url]
    Maximize Browser Window


*** Keywords ***
Get orders
    Create Directory    ${CURDIR}${/}Data
    Download    https://robotsparebinindustries.com/orders.csv      target_file=${CURDIR}${/}Data   overwrite=True
    ${csv_data}     Read table from CSV     Data/orders.csv     header=True
    Return From Keyword     ${csv_data}

*** Keywords ***
Close the annoying modal
    Click Element If Visible    //button[contains(.,"OK")]

*** Keywords ***
Fill the form
    [Arguments]    ${row}
    Select From List By Value  //select[@id="head"]     ${row}[Head]
    Click Element If Visible  id-body-${row}[Body]
    Input Text    //input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    //input[@name="address"]    ${row}[Address]

*** Keywords ****
Place Order
    Click Button When Visible    //button[@id="preview"]
    Click Button When Visible    //button[@id="order"]
    Wait Until Page Contains Element   id:order-another

*** Keywords ***
Reciept To Pdf
    [Arguments]   ${order}
    Wait Until Page Contains Element   id:order-another
    ${html_reciept}=     Get Element Attribute    id:receipt    outerHTML
    Html To Pdf   ${html_reciept}   ${CURDIR}${/}output${/}${order}[Order number].pdf
    Screenshot    id:robot-preview-image    ${CURDIR}${/}output${/}${order}[Order number].png
    ${openpdf}=  Open Pdf  ${CURDIR}${/}output${/}${order}[Order number].pdf
    Add Watermark Image To Pdf  ${CURDIR}${/}output${/}${order}[Order number].png  ${CURDIR}${/}output${/}${order}[Order number].pdf  ${CURDIR}${/}output${/}${order}[Order number].pdf
    Close Pdf  ${openpdf}
    Click Button When Visible    //button[@id="order-another"]

*** Keywords ***
Archive the receipts
    Archive Folder With Zip   ${CURDIR}${/}output  receipts.zip

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Wait Until Keyword Succeeds   8x   .5sec   Place Order
        Reciept To Pdf    ${row}
    END
    Close Browser
    Archive the receipts
    Log    Done.




