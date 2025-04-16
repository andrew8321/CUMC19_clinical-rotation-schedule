import streamlit as st
import pandas as pd

# Load the Excel file
try:
    df = pd.read_excel("Turn.xlsx")
except FileNotFoundError:
    st.error("Turn.xlsx not found. Please make sure the file is in the same directory.")
    st.stop()

# Create a mapping of last characters to specific values
last_char_mapping = {
    "서": "서울",
    "여": "여의도",
    "은": "은평",
    "빈": "빈센트",
    "대": "대전",
    "의": "의정부",
    "부": "부천",
    "인": "인천",
}

def get_weekly_values(df, id_value):
    id_row = df[df["ID"] == id_value]
    if id_row.empty:
        return None
    weekly_values = id_row.filter(like="Week").to_dict(orient="records")[0]
    return weekly_values

def find_exact_match(df, week, value):
    matches = df[df[week] == value]["Name"].tolist()
    return matches

def find_last_char_match(df, week, value):
    last_char = value[-1]
    matches = df[df[week].str.endswith(last_char)]["Name"].tolist()
    return matches

st.title("턴표 요약")

input_id = st.text_input("학번을 입력하세요", value="")
submit_button = st.button("Find Matches")

if submit_button:
    if not input_id.isdigit():
        st.error("학번은 숫자로 입력해주세요.")
    else:
        id_value = int(input_id)
        weekly_values = get_weekly_values(df, id_value)

        if weekly_values is None:
            st.error("ID not found")
        else:
            input_name = df[df["ID"] == id_value]["Name"].iloc[0]

            exact_matches = {}
            last_char_matches = {}

            for week, value in weekly_values.items():
                exact_match = find_exact_match(df, week, value)
                exact_matches[week] = [name for name in exact_match if name != input_name]

                last_char_match_names = find_last_char_match(df, week, value)
                male_matches = [
                    name
                    for name in last_char_match_names
                    if df[df["Name"] == name]["Gender"].iloc[0] == "남" and name != input_name
                ]
                female_matches = [
                    name
                    for name in last_char_match_names
                    if df[df["Name"] == name]["Gender"].iloc[0] == "여" and name != input_name
                ]
                last_char_matches[week] = {"Male": male_matches, "Female": female_matches}

            st.subheader("턴표, 짝턴, 같은 병원 학우")
            for week, value in weekly_values.items():
                matches = exact_matches[week]
                match_str = ", ".join(matches) if matches else "없음"
                last_char = value[-1]
                mapped_last_char = last_char_mapping.get(last_char, last_char)
                male_matches = last_char_matches[week]["Male"]
                female_matches = last_char_matches[week]["Female"]
                male_str = ", ".join(male_matches) if male_matches else "없음"
                female_str = ", ".join(female_matches) if female_matches else "없음"

                st.subheader(week)
                st.write(f"병원: {mapped_last_char}")
                st.write(f"과: {value} - 짝턴: {match_str}")
                st.subheader("같은 병원턴 학우들")
                st.write(f"남자: {male_str}")
                st.write(f"여자: {female_str}")
                st.markdown("---")