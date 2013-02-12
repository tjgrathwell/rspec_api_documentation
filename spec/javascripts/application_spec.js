describe('Application', function() {
    var urlParamField, wurlForm, wurl;
    beforeEach(function() {
        urlParamField = wurlForm = wurl = null;
    });

    afterEach(function() {
        $('#jasmine_content').empty();
    });

    describe("changing URL Parameters", function() {
        beforeEach(function() {
            loadFixture('wurl_post.html');
        });

        it('sets the new URL in the disabled text field', function(){
            urlParamField.val("5").trigger('keyup');
            expect(wurlForm.find("input#wurl_request_url").val()).toBe("/something/5");
            expect(wurl.url()).toContain('/something/5');
        });

        describe("when you enter an invalid id", function() {
            it("doesn't update", function() {
                var originalUrl = wurl.url();
                urlParamField.val("abc").trigger('keyup');
                expect(wurl.url()).toBe(originalUrl);
            });

            it("doesn't update for blanks", function() {
                var originalUrl = wurl.url();
                urlParamField.val("").trigger('keyup');
                expect(wurl.url()).toBe(originalUrl)
            });
        });
    });

    describe('when the request is a POST/PUT', function(){
        beforeEach(function() {
            loadFixture('wurl_post.html');
        });

        it("does not show the Query params area", function() {
            expect($("span:contains(Query)")).not.toExist();
        });

        it("shows the add form parameters button", function() {
            expect($(".add_form_parameter")).toExist();
        });

        it("shows the trash icon for form parameters button", function() {
            expect($(".trash_form_parameters")).toExist();
        });

        describe("when the add form parameter button is clicked", function() {
            it("shows a new row", function() {
                expect($(".post_body_pair").length).toEqual(4);
                $(".add_form_parameter").click();
                expect($(".post_body_pair").length).toEqual(5);
                expect($(".post_body_pair:last").find(".delete_body_param")).toExist();
            });

            it("includes the new parameter in the payload", function() {
                $(".add_form_parameter").click();
                $(".post_body_pair:last .key").val("summer");
                $(".post_body_pair:last .value").val("happiness");
                expect(wurl.getBody()).toContain("summer=happiness");
            });

            it("does not generate the new row by cloning the first row", function() {
                $(".post_body_pair:first").append("Hello");
                $(".add_form_parameter").click();
                expect($(".post_body_pair:last").text()).not.toContain("Hello");
            });
        });

        describe("removing form parameters", function() {
            var animated;

            beforeEach(function() {
                animated = false;
                spyOn($.fn, "slideUp").andCallFake(function(callback) {
                    animated = true;
                    callback();
                });
            });

            describe("by clicking the trash form parameters button", function() {
                beforeEach(function() {
                    $(".post_body_pair").eq(0).find(".value").val("1"); // required
                    $(".post_body_pair").eq(1).find(".value").val("2"); // required
                    $(".post_body_pair").eq(2).find(".value").val("3"); // removable
                    $(".post_body_pair").eq(3).find(".value").val("4"); // required

                    $(".add_form_parameter").click();                   // removable
                    $(".add_form_parameter").click();                   // removable

                    $(".post_body_pair").eq(4).find(".key").val("sunshine");
                    $(".post_body_pair").eq(4).find(".value").val("rainbows");
                    $(".post_body_pair").eq(5).find(".key").val("clouds");
                    $(".post_body_pair").eq(5).find(".value").val("rain");

                    expect($(".post_body_pair").length).toEqual(6);
                    $(".trash_form_parameters").click();
                });

                it("deletes all new parameters", function() {
                    expect($(".post_body_pair").length).toEqual(3);
                    expect(wurl.url()).not.toContain('sunshine');
                    expect(wurl.url()).not.toContain('rainbows');
                    expect(wurl.url()).not.toContain('clouds');
                    expect(wurl.url()).not.toContain('rain');
                });

                it("does not delete the required parameters", function() {
                    expect($(".post_body_pair").eq(0).find(".value")).toHaveValue("1");
                    expect($(".post_body_pair").eq(1).find(".value")).toHaveValue("2");
                    expect($(".post_body_pair").eq(2).find(".value")).toHaveValue("4");
                });

                it("performs jQuery's slideUp animation", function() {
                    expect(animated).toBe(true);
                });
            });

            describe("by clicking one of the remove form parameter buttons", function() {
                beforeEach(function() {
                    expect($(".post_body_pair").length).toEqual(4);

                    var row_to_delete = $(".post_body_pair").eq(2);
                    row_to_delete.find(".key").val('sunshine');
                    row_to_delete.find(".value").val('rainbows');

                    row_to_delete.find(".delete_body_param").click();
                });

                it("removes the parameter", function() {
                    expect($(".post_body_pair").length).toEqual(3);
                    expect(wurl.url()).not.toContain('sunshine');
                    expect(wurl.url()).not.toContain('rainbows');
                });

                it("performs jQuery's slideUp animation", function() {
                    expect(animated).toBe(true);
                });
            });
        });

        describe("the payload", function() {
            it("includes the parameters", function() {
                expect(wurl.getBody()).toContain("foo=bar");
            });

            it("serializes multi value parameters", function() {
                expect(wurl.getBody()).toContain("multi_value_param[]=value1&multi_value_param[]=value2");
            });
        });
    });

    describe('when the request is a GET', function() {
        beforeEach(function() {
            loadFixture('wurl_get.html');
        });

        it("does not show the Body params area", function() {
            expect($("span:contains(Body)")).not.toExist();
        });

        describe('the payload', function(){
            it('has no body', function() {
                expect(wurl.getBody()).toBeFalsy();
            });
        });

        describe('the url', function() {
            it('includes query params', function() {
                expect(wurl.url()).toContain('query=value');
            });
        });
    });

    describe("Clear button", function() {
        beforeEach(function() {
            loadFixture('wurl_post.html');
            this.beforeCount = wurlForm.find("input").size();
            this.inputsWithContent = wurlForm.find("input:disabled[value!='']")
            wurlForm.find("#clear_fields").click();
        });

        it("doesn't add new fields", function() {
            var newCount = wurlForm.find("input").size();
            expect(newCount).toBe(this.beforeCount);
        });

        it("doesn't empty any non-editable fields", function() {
            _.each(this.inputsWithContent, function(input) {
                expect($(input).val()).not.toBe("");
            });
        });
    });

    function loadFixture(file) {
        loadFixtures(file);
        var fixture = $("#jasmine-fixtures .container");
        $('#jasmine_content').append(fixture);
        urlParamField = $("#jasmine_content input.value.url_param");
        wurlForm = $("#jasmine_content .wurl_form");
        wurl = new Wurl(wurlForm);
    }
});
