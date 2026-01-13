# import streamlit as st
# import pandas as pd
# import numpy as np

# # Page configuration
# st.set_page_config(
#     page_title="PropWise Smart Valuator",
#     page_icon="🏠",
#     layout="wide"
# )

# # Header
# st.title("🏠 PropWise Smart Valuator")
# st.subheader("ML-Powered HDB Resale Price Prediction")

# # Sidebar for navigation
# page = st.sidebar.selectbox(
#     "Navigate",
#     ["Price Prediction", "Amenities Explorer", "Connect with Users"]
# )

# # Page 1: Price Prediction
# if page == "Price Prediction":
#     st.header("Predict Your HDB Resale Price")
    
#     col1, col2 = st.columns(2)
    
#     with col1:
#         town = st.selectbox("Town", ["ANG MO KIO", "BEDOK", "BISHAN", "BUKIT MERAH", "CENTRAL AREA", "TAMPINES"])
#         flat_type = st.selectbox("Flat Type", ["2 ROOM", "3 ROOM", "4 ROOM", "5 ROOM", "EXECUTIVE"])
#         storey_range = st.selectbox("Storey Range", ["01 TO 03", "04 TO 06", "07 TO 09", "10 TO 12", "13 TO 15"])
#         floor_area = st.number_input("Floor Area (sqm)", min_value=30, max_value=200, value=90)
    
#     with col2:
#         lease_commence = st.number_input("Lease Commence Date", min_value=1960, max_value=2025, value=1990)
#         address = st.text_input("Block/Street Address", "123 Ang Mo Kio Ave 3")
        
#         # Placeholder for geospatial features
#         st.info("📍 Geospatial features will be calculated based on address")
#         nearest_mrt = st.number_input("Distance to Nearest MRT (km) - Auto-calculated", value=0.5, disabled=True)
#         nearest_school = st.number_input("Distance to Nearest School (km) - Auto-calculated", value=0.3, disabled=True)
    
#     if st.button("🔮 Predict Price", type="primary"):
#         # Placeholder for ML model prediction
#         st.success("Predicted Resale Price: **$450,000 - $480,000**")
#         st.info("💡 This is a mock prediction. Real prediction will use your trained ML model.")

# # Page 2: Amenities Explorer
# elif page == "Amenities Explorer":
#     st.header("Explore Nearby Amenities")
    
#     location = st.text_input("Enter Location", "Ang Mo Kio")
    
#     col1, col2 = st.columns(2)
    
#     with col1:
#         st.subheader("🚇 Nearby MRT Stations")
#         st.write("- Ang Mo Kio MRT (0.5km)")
#         st.write("- Bishan MRT (1.2km)")
    
#     with col2:
#         st.subheader("🍜 Nearby Hawker Centres")
#         st.write("- Ang Mo Kio Hub (0.3km)")
#         st.write("- Block 226 Market (0.6km)")
    
#     col3, col4 = st.columns(2)
    
#     with col3:
#         st.subheader("🏫 Nearby Schools")
#         st.write("- Anderson Primary School (0.4km)")
#         st.write("- CHIJ St. Nicholas (0.8km)")
    
#     with col4:
#         st.subheader("🛒 Nearby Malls")
#         st.write("- AMK Hub (0.5km)")
#         st.write("- Broadway Plaza (0.7km)")
    
#     st.info("🗺️ Interactive map with amenities will be displayed here using folium or plotly")

# # Page 3: Connect with Users
# elif page == "Connect with Users":
#     st.header("Connect with Property Professionals")
    
#     user_type = st.radio("I am a:", ["Home Buyer", "Home Seller", "Property Agent"])
    
#     if user_type == "Home Buyer":
#         st.subheader("Find Your Dream Home")
#         budget = st.slider("Budget Range ($)", 200000, 1000000, (300000, 500000))
#         preferred_towns = st.multiselect("Preferred Towns", ["ANG MO KIO", "BEDOK", "BISHAN", "TAMPINES"])
        
#         if st.button("Find Matches"):
#             st.success("✅ 3 property agents and 12 listings match your criteria!")
    
#     elif user_type == "Home Seller":
#         st.subheader("Get Connected with Buyers")
#         property_address = st.text_input("Property Address")
#         asking_price = st.number_input("Asking Price ($)", min_value=100000, value=400000)
        
#         if st.button("List Property"):
#             st.success("✅ Your property is now listed! 5 interested buyers nearby.")
    
#     else:  # Property Agent
#         st.subheader("Connect with Clients")
#         st.write("View clients looking for properties in your area")
        
#         if st.button("View Leads"):
#             st.success("✅ 8 new leads available in your registered areas!")

# # Footer
# st.sidebar.markdown("---")
# st.sidebar.info("📊 PropWise Smart Valuator v1.0\n\nBuilt with Snowflake, Python & ML")

import streamlit as st
import pandas as pd
import numpy as np

# Page configuration
st.set_page_config(
    page_title="PropWise Smart Valuator",
    page_icon="🏠",
    layout="wide"
)

# Header
st.title("🏠 PropWise Smart Valuator")
st.subheader("ML-Powered HDB Resale Price Prediction")

# Sidebar for navigation
page = st.sidebar.selectbox(
    "Navigate",
    ["Price Prediction", "Amenities Explorer", "Connect with Users"]
)

# Page 1: Price Prediction
if page == "Price Prediction":
    st.header("Predict Your HDB Resale Price")
    
    col1, col2 = st.columns(2)
    
    with col1:
        town = st.selectbox("Town", ["ANG MO KIO", "BEDOK", "BISHAN", "BUKIT MERAH", "CENTRAL AREA", "TAMPINES"])
        flat_type = st.selectbox("Flat Type", ["2 ROOM", "3 ROOM", "4 ROOM", "5 ROOM", "EXECUTIVE"])
        storey_range = st.selectbox("Storey Range", ["01 TO 03", "04 TO 06", "07 TO 09", "10 TO 12", "13 TO 15"])
        floor_area = st.number_input("Floor Area (sqm)", min_value=30, max_value=200, value=90)
    
    with col2:
        lease_commence = st.number_input("Lease Commence Date", min_value=1960, max_value=2025, value=1990)
        address = st.text_input("Block/Street Address", "123 Ang Mo Kio Ave 3")
        
        st.info("📍 Geospatial features will be calculated based on address")
        nearest_mrt = st.number_input("Distance to Nearest MRT (km)", value=0.5, disabled=True)
        nearest_school = st.number_input("Distance to Nearest School (km)", value=0.3, disabled=True)
    
    if st.button("🔮 Predict Price", type="primary"):
        st.success("Predicted Resale Price: **$450,000 - $480,000**")
        st.info("💡 This is a mock prediction. Real prediction will use your trained ML model.")

# Page 2: Amenities Explorer
elif page == "Amenities Explorer":
    st.header("Explore Nearby Amenities")
    
    location = st.text_input("Enter Location", "Ang Mo Kio")
    
    col1, col2 = st.columns(2)
    
    with col1:
        st.subheader("🚇 Nearby MRT Stations")
        st.write("- Ang Mo Kio MRT (0.5km)")
        st.write("- Bishan MRT (1.2km)")
    
    with col2:
        st.subheader("🍜 Nearby Hawker Centres")
        st.write("- Ang Mo Kio Hub (0.3km)")
        st.write("- Block 226 Market (0.6km)")
    
    col3, col4 = st.columns(2)
    
    with col3:
        st.subheader("🏫 Nearby Schools")
        st.write("- Anderson Primary School (0.4km)")
        st.write("- CHIJ St. Nicholas (0.8km)")
    
    with col4:
        st.subheader("🛒 Nearby Malls")
        st.write("- AMK Hub (0.5km)")
        st.write("- Broadway Plaza (0.7km)")
    
    st.info("🗺️ Interactive map with amenities will be displayed here")

# Page 3: Connect with Users
else:
    st.header("Connect with Property Professionals")
    
    user_type = st.radio("I am a:", ["Home Buyer", "Home Seller", "Property Agent"], horizontal=True)
    
    st.markdown("---")
    
    # HOME BUYER DASHBOARD
    if user_type == "Home Buyer":
        st.subheader("🏠 Home Buyer Dashboard")
        
        # Top Metrics
        col1, col2, col3, col4 = st.columns(4)
        with col1:
            st.metric("Saved Properties", "12", "+3")
        with col2:
            st.metric("New Matches", "8", "+2")
        with col3:
            st.metric("Agent Contacts", "5", "+1")
        with col4:
            st.metric("Avg Price in Area", "$450K", "-2%")
        
        st.markdown("---")
        
        # Search Filters
        with st.expander("🔍 Search Filters", expanded=True):
            filter_col1, filter_col2, filter_col3 = st.columns(3)
            
            with filter_col1:
                budget = st.slider("Budget Range ($)", 200000, 1000000, (300000, 500000), step=10000)
            with filter_col2:
                preferred_towns = st.multiselect("Preferred Towns", 
                    ["ANG MO KIO", "BEDOK", "BISHAN", "BUKIT MERAH", "TAMPINES", "JURONG WEST"])
            with filter_col3:
                preferred_flat_types = st.multiselect("Flat Types", 
                    ["3 ROOM", "4 ROOM", "5 ROOM", "EXECUTIVE"])
            
            if st.button("🔎 Search Properties", type="primary"):
                st.success("✅ Found 24 properties matching your criteria!")
        
        st.markdown("---")
        
        # Main Content Area
        tab1, tab2, tab3, tab4 = st.tabs(["📋 Recommended Properties", "⭐ Saved Properties", "👥 Contact Agents", "📊 Market Insights"])
        
        with tab1:
            st.subheader("Properties Matching Your Criteria")
            
            # Mock property listings
            prop_col1, prop_col2 = st.columns(2)
            
            with prop_col1:
                st.markdown("**Block 123 Ang Mo Kio Ave 3**")
                st.write("🏢 4 ROOM | 📏 95 sqm | 🚇 0.3km to MRT")
                st.write("💰 **$425,000** | Match Score: 95%")
                if st.button("View Details", key="prop1"):
                    st.info("Property details will be displayed here")
                st.markdown("---")
            
            with prop_col2:
                st.markdown("**Block 456 Bishan Street 12**")
                st.write("🏢 4 ROOM | 📏 92 sqm | 🚇 0.5km to MRT")
                st.write("💰 **$445,000** | Match Score: 88%")
                if st.button("View Details", key="prop2"):
                    st.info("Property details will be displayed here")
                st.markdown("---")
        
        with tab2:
            st.subheader("Your Saved Properties")
            st.info("You have 12 saved properties. Click to view and compare.")
            
            # Saved properties list
            saved_data = {
                "Property": ["Block 123 AMK Ave 3", "Block 789 Bedok North", "Block 321 Tampines St 11"],
                "Flat Type": ["4 ROOM", "5 ROOM", "4 ROOM"],
                "Price": ["$425,000", "$520,000", "$438,000"],
                "Distance to MRT": ["0.3km", "0.6km", "0.4km"]
            }
            st.dataframe(pd.DataFrame(saved_data), use_container_width=True)
            
            if st.button("Compare Selected Properties"):
                st.success("Comparison view will be displayed here")
        
        with tab3:
            st.subheader("Property Agents in Your Area")
            
            agent_col1, agent_col2, agent_col3 = st.columns(3)
            
            with agent_col1:
                st.markdown("**Agent Sarah Tan**")
                st.write("⭐ Rating: 4.8/5")
                st.write("📍 Specializes in: Ang Mo Kio, Bishan")
                st.write("✅ Deals Closed: 45")
                if st.button("Contact Agent", key="agent1"):
                    st.success("Contact details sent to your email!")
            
            with agent_col2:
                st.markdown("**Agent Michael Lim**")
                st.write("⭐ Rating: 4.6/5")
                st.write("📍 Specializes in: Bedok, Tampines")
                st.write("✅ Deals Closed: 38")
                if st.button("Contact Agent", key="agent2"):
                    st.success("Contact details sent to your email!")
            
            with agent_col3:
                st.markdown("**Agent Jessica Wong**")
                st.write("⭐ Rating: 4.9/5")
                st.write("📍 Specializes in: Central Area, Bishan")
                st.write("✅ Deals Closed: 52")
                if st.button("Contact Agent", key="agent3"):
                    st.success("Contact details sent to your email!")
        
        with tab4:
            st.subheader("Market Insights for Your Search Areas")
            
            insight_col1, insight_col2 = st.columns(2)
            
            with insight_col1:
                st.markdown("**Average Prices by Town**")
                price_data = {
                    "Town": ["Ang Mo Kio", "Bishan", "Bedok", "Tampines"],
                    "Avg Price (4 ROOM)": [425000, 485000, 445000, 438000]
                }
                st.bar_chart(pd.DataFrame(price_data).set_index("Town"))
            
            with insight_col2:
                st.markdown("**Price Trends (Last 6 Months)**")
                st.line_chart(pd.DataFrame({
                    "Month": ["Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
                    "Avg Price": [420000, 425000, 430000, 435000, 440000, 445000]
                }).set_index("Month"))
    
    # HOME SELLER DASHBOARD
    elif user_type == "Home Seller":
        st.subheader("🏡 Home Seller Dashboard")
        
        # Top Metrics
        col1, col2, col3, col4 = st.columns(4)
        with col1:
            st.metric("Property Views", "47", "+12")
        with col2:
            st.metric("Interested Buyers", "8", "+3")
        with col3:
            st.metric("Days Listed", "15", "")
        with col4:
            st.metric("Market Activity", "High", "↑")
        
        st.markdown("---")
        
        # Main Content Area
        tab1, tab2, tab3, tab4 = st.tabs(["🏠 My Listing", "👥 Interested Buyers", "📊 Market Analytics", "🤝 Connect with Agents"])
        
        with tab1:
            st.subheader("Your Property Listing")
            
            list_col1, list_col2 = st.columns(2)
            
            with list_col1:
                st.markdown("**Property Details**")
                property_address = st.text_input("Property Address", "Block 123 Ang Mo Kio Ave 3")
                property_town = st.selectbox("Town", ["ANG MO KIO", "BEDOK", "BISHAN", "TAMPINES"], key="seller_town")
                property_flat = st.selectbox("Flat Type", ["3 ROOM", "4 ROOM", "5 ROOM", "EXECUTIVE"], key="seller_flat")
                property_area = st.number_input("Floor Area (sqm)", min_value=30, max_value=200, value=95)
            
            with list_col2:
                st.markdown("**Pricing Strategy**")
                predicted_price = st.info("🔮 **ML Predicted Price: $425,000 - $445,000**")
                asking_price = st.number_input("Your Asking Price ($)", min_value=100000, value=435000, step=5000)
                
                # Price comparison
                if asking_price > 445000:
                    st.warning("⚠️ Your asking price is above predicted range. This may take longer to sell.")
                elif asking_price < 425000:
                    st.success("✅ Competitive pricing! Likely to attract buyers quickly.")
                else:
                    st.info("👍 Your asking price is within the predicted range.")
            
            if st.button("📤 Update Listing", type="primary"):
                st.success("✅ Your property listing has been updated!")
        
        with tab2:
            st.subheader("Interested Buyers")
            
            st.write("**Recent Inquiries**")
            buyers_data = {
                "Buyer": ["Buyer A", "Buyer B", "Buyer C", "Buyer D"],
                "Budget Range": ["$400K-$450K", "$420K-$460K", "$430K-$470K", "$410K-$440K"],
                "Match Score": ["95%", "88%", "92%", "85%"],
                "Status": ["Pending", "Viewed", "Interested", "Pending"]
            }
            st.dataframe(pd.DataFrame(buyers_data), use_container_width=True)
            
            buyer_detail_col1, buyer_detail_col2 = st.columns(2)
            
            with buyer_detail_col1:
                st.markdown("**High Priority Leads**")
                st.write("🔥 **Buyer A** - Budget matches asking price")
                st.write("📧 Contact: buyer.a@email.com")
                if st.button("Contact Buyer A", key="buyer_a"):
                    st.success("Message sent to Buyer A!")
            
            with buyer_detail_col2:
                st.markdown("**Recent Activity**")
                st.write("• Buyer B viewed your listing 2 hours ago")
                st.write("• Buyer C saved your property")
                st.write("• Buyer D requested more photos")
        
        with tab3:
            st.subheader("Market Analytics for Your Area")
            
            analytics_col1, analytics_col2 = st.columns(2)
            
            with analytics_col1:
                st.markdown("**Recent Sales in Your Town**")
                sales_data = {
                    "Address": ["Block 111 AMK Ave 1", "Block 234 AMK Ave 5", "Block 567 AMK Ave 8"],
                    "Flat Type": ["4 ROOM", "4 ROOM", "5 ROOM"],
                    "Sold Price": ["$430,000", "$438,000", "$525,000"],
                    "Days to Sell": [12, 18, 25]
                }
                st.dataframe(pd.DataFrame(sales_data), use_container_width=True)
            
            with analytics_col2:
                st.markdown("**Average Time to Sell**")
                st.metric("4 ROOM in Ang Mo Kio", "18 days", "-3 days")
                st.markdown("**Pricing Recommendations**")
                st.write("• Properties priced at $430K-$445K sell fastest")
                st.write("• Current demand is HIGH in your area")
                st.write("• Best time to list: Now!")
        
        with tab4:
            st.subheader("Recommended Property Agents")
            
            st.write("Connect with top-performing agents to help sell your property faster")
            
            seller_agent_col1, seller_agent_col2, seller_agent_col3 = st.columns(3)
            
            with seller_agent_col1:
                st.markdown("**Agent David Chen**")
                st.write("⭐ Rating: 4.9/5")
                st.write("📍 Expert in: Ang Mo Kio")
                st.write("💼 Commission: 2%")
                st.write("⏱️ Avg Days to Sell: 15")
                if st.button("Request Consultation", key="seller_agent1"):
                    st.success("Agent David will contact you within 24 hours!")
            
            with seller_agent_col2:
                st.markdown("**Agent Rachel Ng**")
                st.write("⭐ Rating: 4.7/5")
                st.write("📍 Expert in: Ang Mo Kio, Bishan")
                st.write("💼 Commission: 2%")
                st.write("⏱️ Avg Days to Sell: 18")
                if st.button("Request Consultation", key="seller_agent2"):
                    st.success("Agent Rachel will contact you within 24 hours!")
            
            with seller_agent_col3:
                st.markdown("**Agent Kevin Tan**")
                st.write("⭐ Rating: 4.8/5")
                st.write("📍 Expert in: Central Area")
                st.write("💼 Commission: 2.5%")
                st.write("⏱️ Avg Days to Sell: 14")
                if st.button("Request Consultation", key="seller_agent3"):
                    st.success("Agent Kevin will contact you within 24 hours!")
    
    # PROPERTY AGENT DASHBOARD
    else:
        st.subheader("🏢 Property Agent Dashboard")
        
        # Top Metrics
        col1, col2, col3, col4, col5 = st.columns(5)
        with col1:
            st.metric("Active Listings", "18", "+2")
        with col2:
            st.metric("New Leads", "12", "+5")
        with col3:
            st.metric("Pending Deals", "6", "+1")
        with col4:
            st.metric("Closed This Month", "4", "+2")
        with col5:
            st.metric("Client Rating", "4.8/5", "+0.1")
        
        st.markdown("---")
        
        # Main Content Area
        tab1, tab2, tab3, tab4 = st.tabs(["🎯 Client Leads", "📋 My Listings", "📊 Market Intelligence", "🤝 Client Matching"])
        
        with tab1:
            st.subheader("New Client Leads")
            
            lead_type = st.radio("Show:", ["All Leads", "Buyers", "Sellers"], horizontal=True)
            
            st.markdown("**High Priority Leads**")
            
            leads_data = {
                "Client": ["John Tan", "Mary Lim", "David Wong", "Sarah Ong"],
                "Type": ["Buyer", "Seller", "Buyer", "Seller"],
                "Location Interest": ["Ang Mo Kio", "Bishan", "Bedok", "Tampines"],
                "Budget/Property Value": ["$400K-$450K", "$520K", "$380K-$420K", "$465K"],
                "Priority": ["🔥 High", "⭐ Medium", "🔥 High", "⭐ Medium"],
                "Days Active": [2, 5, 1, 3]
            }
            st.dataframe(pd.DataFrame(leads_data), use_container_width=True)
            
            lead_col1, lead_col2 = st.columns(2)
            
            with lead_col1:
                st.markdown("**Lead Details: John Tan**")
                st.write("👤 **Type:** First-time Buyer")
                st.write("💰 **Budget:** $400K - $450K")
                st.write("📍 **Preferred:** Ang Mo Kio, Bishan")
                st.write("🏢 **Looking for:** 4 ROOM")
                st.write("⏰ **Timeline:** Urgent (Within 2 months)")
                if st.button("Contact John Tan", key="lead1"):
                    st.success("✅ Contact initiated! Details sent to your email.")
            
            with lead_col2:
                st.markdown("**Recommended Actions**")
                st.info("💡 John Tan's budget matches 3 of your active listings!")
                if st.button("View Matching Properties", key="match_lead1"):
                    st.success("Showing 3 matching properties...")
                if st.button("Schedule Viewing", key="schedule1"):
                    st.success("Viewing scheduled for tomorrow at 2 PM")
        
        with tab2:
            st.subheader("Your Active Listings")
            
            listing_filter = st.selectbox("Filter by:", ["All Listings", "High Activity", "Price Reduced", "New Listings"])
            
            listings_data = {
                "Property": ["Block 123 AMK Ave 3", "Block 456 Bishan St 12", "Block 789 Bedok North"],
                "Type": ["4 ROOM", "5 ROOM", "4 ROOM"],
                "Asking Price": ["$435,000", "$520,000", "$448,000"],
                "Days Listed": [15, 8, 22],
                "Views": [47, 32, 58],
                "Inquiries": [8, 5, 12],
                "Status": ["Active", "Active", "Active"]
            }
            st.dataframe(pd.DataFrame(listings_data), use_container_width=True)
            
            listing_col1, listing_col2 = st.columns(2)
            
            with listing_col1:
                st.markdown("**Listing Performance**")
                st.write("🏆 **Top Performer:** Block 789 Bedok North")
                st.write("👁️ 58 views in 22 days")
                st.write("📧 12 inquiries")
                st.write("💡 **Suggestion:** Schedule viewings with top 3 inquiries")
            
            with listing_col2:
                st.markdown("**Action Items**")
                st.warning("⚠️ Block 123 AMK: Consider price adjustment")
                st.info("ℹ️ Block 456 Bishan: New listing performing well")
                st.success("✅ Block 789 Bedok: High interest - follow up leads!")
        
        with tab3:
            st.subheader("Market Intelligence")
            
            intel_col1, intel_col2 = st.columns(2)
            
            with intel_col1:
                st.markdown("**Hot Areas This Month**")
                hot_areas = {
                    "Town": ["Tampines", "Bedok", "Ang Mo Kio", "Bishan"],
                    "Avg Days to Sell": [12, 15, 18, 16],
                    "Demand": ["🔥 Very High", "🔥 High", "⭐ Medium", "⭐ Medium"]
                }
                st.dataframe(pd.DataFrame(hot_areas), use_container_width=True)
                
                st.markdown("**Price Trends**")
                st.line_chart(pd.DataFrame({
                    "Month": ["Jul", "Aug", "Sep", "Oct", "Nov", "Dec"],
                    "4 ROOM": [425000, 430000, 435000, 440000, 445000, 450000],
                    "5 ROOM": [520000, 525000, 530000, 535000, 540000, 545000]
                }).set_index("Month"))
            
            with intel_col2:
                st.markdown("**Market Insights**")
                st.success("📈 Overall market trend: **UPWARD**")
                st.write("• 4 ROOM prices increased 5.8% this year")
                st.write("• 5 ROOM prices increased 4.8% this year")
                st.write("• Average time to sell: **16 days** (-2 days)")
                st.write("• Buyer demand is **HIGH** in mature estates")
                
                st.markdown("**Your Area Performance**")
                st.metric("Ang Mo Kio Market Activity", "High", "+12%")
                st.metric("Average Selling Price (4 ROOM)", "$445K", "+3.5%")
                st.metric("Inventory Level", "Medium", "")
        
        with tab4:
            st.subheader("Smart Client Matching")
            
            st.write("AI-powered matching between your buyers and sellers")
            
            match_col1, match_col2 = st.columns(2)
            
            with match_col1:
                st.markdown("**Top Matches**")
                
                st.write("🎯 **Match 1** (95% compatibility)")
                st.write("Buyer: John Tan ↔️ Listing: Block 123 AMK")
                st.write("• Budget: $400K-$450K ✅")
                st.write("• Location: Ang Mo Kio ✅")
                st.write("• Flat Type: 4 ROOM ✅")
                if st.button("Introduce Match 1", key="match1"):
                    st.success("Introduction sent to both parties!")
                
                st.markdown("---")
                
                st.write("🎯 **Match 2** (88% compatibility)")
                st.write("Buyer: David Wong ↔️ Listing: Block 789 Bedok")
                st.write("• Budget: $380K-$420K ⚠️ (Slightly below)")
                st.write("• Location: Bedok ✅")
                st.write("• Flat Type: 4 ROOM ✅")
                if st.button("Introduce Match 2", key="match2"):
                    st.success("Introduction sent to both parties!")
            
            with match_col2:
                st.markdown("**Matching Statistics**")
                st.metric("Total Possible Matches", "24", "+6")
                st.metric("Matches Introduced This Week", "8", "+3")
                st.metric("Successful Conversions", "65%", "+5%")
                
                st.markdown("**Recent Activity**")
                st.write("• Match introduced 2 hours ago: In discussion")
                st.write("• Match from yesterday: Viewing scheduled")
                st.write("• Match from last week: Deal closed! 🎉")
                
                if st.button("🔎 Find More Matches"):
                    st.success("Searching for new matches... Found 3 new potential matches!")

# Footer
st.sidebar.markdown("---")
st.sidebar.info("📊 PropWise Smart Valuator v1.0\n\nBuilt with Snowflake, Python & ML")
