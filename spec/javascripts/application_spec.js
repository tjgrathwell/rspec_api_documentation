describe('Application', function() {
    beforeEach(function() {
        loadFixtures('wurl_body.html');
        var fixture = $("#jasmine-fixtures .container");
        $('#jasmine_content').append(fixture);
        this.urlParamField = $("#jasmine_content input.value.url_param");
        this.wurlForm = $("#jasmine_content .wurl_form");
        this.wurl = new Wurl(this.wurlForm);
    });

    afterEach(function() {
        $('#jasmine_content').empty();
    });

    describe("When changing URL Parameters", function() {
        it('sets the new URL in the disabled text field', function(){
            this.urlParamField.val("5").trigger('keyup');
            expect(this.wurlForm.find("input#wurl_request_url").val()).toBe("/something/5");
            expect(this.wurl.url()).toBe('/something/5')
        });

        describe("when you enter an invalid id", function() {
            it("doesn't update", function() {
                var originalUrl = this.wurl.url();
                this.urlParamField.val("abc").trigger('keyup');
                expect(this.wurl.url()).toBe(originalUrl);
            });

            it("doesn't update for blanks", function() {
                var originalUrl = this.wurl.url();
                this.urlParamField.val("").trigger('keyup');
                expect(this.wurl.url()).toBe(originalUrl)
            });
        });
    });

    describe("Getting the data for POST body parameters", function() {
        it("should have the right parameters", function() {
            expect(this.wurl.getData()).toContain("foo=bar&baz=Bar!");
        });
    });

    describe("Clear button", function() {
        beforeEach(function() {
            this.beforeCount = this.wurlForm.find("input").size();
            this.inputsWithContent = this.wurlForm.find("input:disabled[value!='']")
            this.wurlForm.find("#clear_fields").click();
        });

        it("doesn't add new fields", function() {
            var newCount = this.wurlForm.find("input").size();
            expect(newCount).toBe(this.beforeCount);
        });

        it("doesn't empty any non-editable fields", function() {
            _.each(this.inputsWithContent, function(input) {
                expect($(input).val()).not.toBe("");
            });
        });
    });
});
