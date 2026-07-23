from guc_portal._parse import parse_course_grades


def test_nested_layout_table_is_not_parsed_twice() -> None:
    html = """
    <table id="layout">
      <tr><td>
        <table id="grades">
          <tr>
            <th>Quiz/Assignment</th><th>Element Name</th>
            <th>Grade</th><th>Prof./Lecturer/TA</th>
          </tr>
          <tr>
            <td>Final Grade</td><td>Quiz</td>
            <td>7 / 10</td><td>Instructor</td>
          </tr>
          <tr>
            <td></td><td>Project</td>
            <td>55 / 95</td><td>Instructor</td>
          </tr>
        </table>
      </td></tr>
    </table>
    <table id="summary">
      <tr><th>Course</th><th>Percentage</th></tr>
      <tr><td>ICS501 Software Project I</td><td>65.3</td></tr>
    </table>
    """
    grades = parse_course_grades(html, "ICS501", "Winter 2024")
    assert [(item.element, item.grade) for item in grades.items] == [
        ("Quiz", "7 / 10"),
        ("Project", "55 / 95"),
    ]
    assert grades.percentages == {"ICS501 Software Project I": "65.3"}
