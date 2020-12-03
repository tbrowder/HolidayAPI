unit module Constants;

our constant $afday is export = 'Armed Forces Day';

# desired holiday names => holidayapi names
constant %my-hnames := {
        # key:   my desired name
        # value: holidayapi name
        "Armed Forces Day" => "Armed Forces Day", # not usually in holidayapi database
        "Christmas Day"    => "Christmas Day",
        "Christmas Eve"    => "Christmas Eve",
        "Columbus Day"     => "Columbus Day",
        "Easter"           => "Easter",
        "Election Day"     => "Election Day",
        "Fathers Day"      => "Father's Day",
        "Flag Day"         => "Flag Day",
        "GW Birthday"      => "George Washington's Birthday",
        "Good Friday"      => "Good Friday",
        "Grand Parent Day" => "National Grandparent's Day",
        "Groundhog Day"    => "Groundhog Day",
        "Halloween"        => "Halloween",
        "Independence Day" => "Independence Day",
        "Labor Day"        => "Labor Day",
        "MLK Day"          => "Martin Luther King, Jr. Day",
        "Memorial Day"     => "Memorial Day",
        "Mothers Day"      => "Mother's Day",
        "New Years Day"    => "New Year's Day",
        "New Years Eve"    => "New Year's Eve",
        "Palm Sunday"      => "Palm Sunday",
        "Perl Harbor Day"  => "Pearl Harbor Remembrance Day",
        "St Patricks Day"  => "St. Patrick's Day",
        "Thanksgiving"     => "Thanksgiving Day",
        "Valentines Day"   => "Valentine's Day",
        "Veterans Day"     => "Veterans Day",
};

# holidayapi names => desired holiday namesx
our %hnames is export = %my-hnames.antipairs;

# Federal holidays data from:
#    https://www.opm.gov/policy-data-oversight/snow-dismissal-procedures/federal-holidays/#url=YYYY
# use holidayapi name here:
constant %fed-holidays is export = set [
    "New Year's Day",
    "Martin Luther King, Jr. Day",
    "George Washington's Birthday",
    "Memorial Day",
    "Independence Day",
    "Labor Day",
    "Columbus Day",
    "Veterans Day",
    "Thanksgiving Day",
    "Christmas Day",
];

constant %afdays is export = {
    # US Armed Forces Day
    # third Saturday in May
    #   key:   YYYY
    #   value: DD (third Saturday in May)
    2019 => "18",
    2020 => "16",
    2021 => "15",
    2022 => "21",
    2023 => "20",
    2024 => "18",
    2025 => "17",
    2026 => "16",
    2027 => "15",
    2028 => "20",
    2029 => "19",
};
